#!/usr/bin/env ruby
# osxnbbuilder -- Christian Koch <cfkoch@sdf.lonestar.org>
#
# This is the script that will be invoked by Platypus. It's the main driver
# that holds everything together.

require 'shellwords'

HERE = File.absolute_path(File.dirname(__FILE__))
DRY_RUN = ARGV.any? { |arg| arg == "-n" }

$LOAD_PATH.unshift(File.join(HERE, "lib"))
require 'Pashua'
include Pashua

FOSSIL = File.join(HERE, "bin", "fossil")
PASHUA_LOC = File.join(HERE, "app")

LIBEXECDIR = File.join(HERE, "libexec")
NETBSD_SRC = File.join(HERE, "src")
SCREEN1_GUI_CONF = File.join(HERE, "netbsdbuilder-pashua.conf")
SCREEN2_GUI_CONF_SCRIPT = File.join(HERE, "libexec", "configs-for-port.rb")

#####

def target?(t)
  return @screen1_conf[t] == "1"
end

#####

$stdout.puts("Launching NetBSD Builder Wizard...")
@screen1_conf = pashua_run(File.read(SCREEN1_GUI_CONF), "", PASHUA_LOC)
exit(0) if @screen1_conf["cancel"] == "1"


# You have to have the sources available *now* instead of later, so
# that we can tell the user the available kernel configs.
Dir.chdir(NETBSD_SRC)
system %Q('#{FOSSIL}' open src.fossil)
system %Q('#{FOSSIL}' checkout #{@screen1_conf["branch"]})
system %Q('#{FOSSIL}' pull)


# The content of the second screen depends on the values given in the first
# screen.
Dir.chdir(HERE)
cmd = Shellwords.shelljoin(["ruby", SCREEN2_GUI_CONF_SCRIPT,
  @screen1_conf["port"]])
@screen2_gui_conf = `#{cmd}`
@screen2_conf = pashua_run(@screen2_gui_conf, "", PASHUA_LOC)
exit(0) if @screen2_conf["cancel"] == "1"


# Find out which targets we are going to build and construct a string of
# them to be pased to build.sh(1).
targets = []

@screen1_conf.keys.select { |k| k =~ /^target\-/ }.each { |target|
  real_name = target.sub("target-", "")

  if target?(target)
    real_name = "kernel=#{@screen2_conf['config']}" if real_name == "kernel"
    targets.push(real_name) 
  end
}

targets_s = targets.join(" ")


# Construct the build.sh invocation.
build_cmd = sprintf("./build.sh -U -j%d -N%d -m%s -a%s %s",
  @screen1_conf["njobs"].to_i, @screen1_conf["noiselevel"].to_i,
  @screen1_conf["port"], @screen2_conf["arch"], targets_s)

if DRY_RUN
  $stdout.print("-------\nDRY RUN\n-------\n")
  $stdout.puts(@screen1_conf.inspect)
  $stdout.puts(@screen2_conf.inspect)
  $stdout.puts(build_cmd.inspect)
  exit 0
else
  # XXX really should inject the environment with IO.popen or whatever
  ENV["HOST_SH"] = "/bin/sh"
  ENV["HAVE_LLVM"] = "yes"
  ENV["MKLLVM"] = "yes"

  Dir.chdir(NETBSD_SRC)
  system(build_cmd)
end
