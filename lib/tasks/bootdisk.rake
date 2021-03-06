require 'date'
require 'tmpdir'

namespace :bootdisk do
  def outputdir
    if ENV['OUTPUT']
      File.directory?(ENV['OUTPUT']) ? ENV['OUTPUT'] : File.dirname(ENV['OUTPUT'])
    elsif File.writable?(Dir.pwd)
      Dir.pwd
    else
      Dir.tmpdir
    end
  end

  namespace :generate do
    desc 'Generate a static boot disk for a specific host.  NAME=fqdn, OUTPUT path'
    task :host => :environment do
      host = Host::Base.find_by_name(ENV['NAME']) || raise("cannot find host '#{ENV['NAME']}', specify NAME=fqdn")
      tmpl = host.bootdisk_template_render

      ForemanBootdisk::ISOGenerator.generate(:ipxe => tmpl, :dir => outputdir) do |image|
        output = ENV['OUTPUT'] || File.join(outputdir, "#{host.name}.iso")
        FileUtils.mv image, output
        puts "Wrote #{output}"
      end
    end

    desc 'Generate a full boot disk for a specific host with the OS bootloader included.  NAME=fqdn, OUTPUT path'
    task :full_host => :environment do
      host = Host::Base.find_by_name(ENV['NAME']) || raise("cannot find host '#{ENV['NAME']}', specify NAME=fqdn")
      ForemanBootdisk::ISOGenerator.generate_full_host(host, :dir => outputdir) do |image|
        output = ENV['OUTPUT'] || File.join(outputdir, "#{host.name}_#{Date.today.strftime('%Y%m%d')}.iso")
        FileUtils.cp image, output
        puts "Wrote #{output}"
      end
    end

    desc 'Generate a generic boot disk.  OUTPUT=path'
    task :generic => :environment do
      tmpl = ForemanBootdisk::Renderer.new.generic_template_render

      ForemanBootdisk::ISOGenerator.generate(:ipxe => tmpl, :dir => outputdir) do |image|
        output = ENV['OUTPUT'] || File.join(outputdir, "bootdisk_#{URI.parse(Setting[:foreman_url]).host}.iso")
        FileUtils.cp image, output
        puts "Wrote #{output}"
      end
    end
  end
end

# Tests
namespace :test do
  desc "Test foreman_bootdisk"
  Rake::TestTask.new(:foreman_bootdisk) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ["test",test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
  end
end

Rake::Task[:test].enhance do
  Rake::Task['test:foreman_bootdisk'].invoke
end

load 'tasks/jenkins.rake'
if Rake::Task.task_defined?(:'jenkins:unit')
  Rake::Task["jenkins:unit"].enhance do
    Rake::Task['test:foreman_bootdisk'].invoke
  end
end
