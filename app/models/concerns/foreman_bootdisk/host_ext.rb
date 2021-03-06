require 'uri'

module ForemanBootdisk::HostExt
  extend ActiveSupport::Concerns

  def bootdisk_template
    ConfigTemplate.find_by_name(Setting[:bootdisk_host_template]) || raise(::Foreman::Exception.new(N_('Unable to find template specified by %s setting'), 'bootdisk_host_template'))
  end

  def bootdisk_template_render
    @host = self
    pxe_render(bootdisk_template.template)
  end

  def bootdisk_chain_url(mac = self.mac, action = 'iPXE')
    u = URI.parse(foreman_url(action))
    u.query = "#{u.query}&mac=#{mac}"
    u.fragment = nil
    u.to_s
  end

  def bootdisk_raise(*args)
    raise ::Foreman::Exception.new(*args)
  end
end
