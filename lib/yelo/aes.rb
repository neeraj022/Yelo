require 'openssl'
require 'digest/sha2'
require 'json'

class Yelo::Aes
  
  def self.bin2hex(str)
    str.unpack('C*').map{ |b| "%02X" % b }.join('')
  end
  
  def self.hex2bin(str)
    [str].pack "H*"
  end
  # the encryption in ruby
  # you can provide salt and iv, or not
  # if not it will be generated for you
  def self.encrypt(salt=nil, iv=nil, payload, pwd)
    cipher = OpenSSL::Cipher::Cipher.new('AES-256-CBC')
    cipher.encrypt
    if salt.nil?
      salt = OpenSSL::Random.random_bytes(8)
    else
      salt = hex2bin(salt)
    end
    if iv.nil?
      iv = cipher.random_iv
    else
      iv = hex2bin(iv)
    end
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(pwd, salt, 1024, cipher.key_len)
    cipher.key = key
    # iv = cipher.random_iv
    cipher.iv = iv
    cipher.padding = 1 
    encrypted_binary = cipher.update(payload) + cipher.final
   
    return bin2hex(salt), bin2hex(iv), bin2hex(encrypted_binary) 
  end
   
  # the decryption
  # you must provide the salt, iv, and encrypted paylaod
  # you need the password too, but that can be in config
  def self.decrypt(salt, iv, encrypted_payload, pwd)
   
    cipher = OpenSSL::Cipher::Cipher.new('AES-256-CBC')
    cipher.decrypt
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(pwd, hex2bin(salt), 1024, cipher.key_len)
    cipher.key = key
    cipher.iv = hex2bin(iv)
    cipher.padding = 1 
    plaintext = cipher.update(hex2bin(encrypted_payload))
    plaintext << cipher.final
   
    return plaintext
  end

end