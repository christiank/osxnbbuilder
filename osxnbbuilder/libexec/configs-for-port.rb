#!/usr/bin/env ruby
#
# NetBSD Builder -- Arch and kernel conf dialog
# Christian Koch <cfkoch@sdf.lonestar.org>
#
# Given the name of a NetBSD port, return the kernel configurations that are
# associated with it.

require 'erb'
require 'shellwords'

@port = ARGV.shift
exit(1) if not @port

SRCDIR = File.absolute_path(File.join(File.dirname(__FILE__), "..", "src"))

DEFAULT_CONFIG_MAP = {
  "evbarm" => "RPI",
}

DEFAULT_ARCH_MAP = {
  "evbarm" => "arm",
}

TEMPLATE = <<-EOF
*.title = NetBSD Builder

logo.type = image
logo.path = ./img/netbsd-tb-small.png

msg.type = text
msg.text = Configuration for port "<%= @port %>"

arch.type = popup
arch.label = Architecture
arch.default = <%= @all_arches.first %>
<% @all_arches.each do |arch| %>
arch.option = <%= arch %>
<% end %>

config.type = popup
config.label = Kernel configuration file
config.default = <%= DEFAULT_CONFIG_MAP[@port] || "GENERIC" %>
<% @all_configs.each do |conf| %>
config.option = <%= conf %>

cancel.type = cancelbutton
<% end %>
EOF

def configs_for_port(port)
  portdir = File.join(SRCDIR, "sys", "arch", @port)
  return false if not File.directory?(portdir)

  return Dir.entries(File.join(portdir, "conf")).
    reject { |f|
      regexen = [
        /^\./, /^mk\./, /^files\./, /^std\./, /README\.#{@port}/, /^majors\./,
        /^kern\./, /^Makefile/, /^*\.inc/, /^*\.x/, /^*ldscript\./,
        /^stand\./,
      ]
      regexen.any? { |r| f =~ r }
    }.sort
end

# XXX deal with those ports that don't return anything useful, such as 'xen'
def arches_for_port(port)
  Dir.chdir(SRCDIR)

  return `./build.sh -m#{port} list-arch`.
    split("\n").
    map { |line| line.split(/\s+/) }.
    map { |ary| ary[1].sub("MACHINE_ARCH=", "") }
end

@all_configs = configs_for_port(@port) || exit(1)
@all_arches = arches_for_port(@port) || exit(1)
$stdout.puts(ERB.new(TEMPLATE, nil, '<>').result(binding))
exit 0
