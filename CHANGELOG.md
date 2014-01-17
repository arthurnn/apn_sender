# Version 2.0
## 2.0.2
- Add default file so we dont need to require 'apn' anymore
- Change backend switch:
  Use simple backend per default, also allow changes.
  Now you can change the backend using:
        APN.backend = :sidekiq

## 2.0.1
- Use bytesize to truncate alert when necessary
- Better calculation on payload size. (botvinik)
- Fix generating payload should use bytesize. (piotr-sokolowski)
- Rescuing and repairing broken connections (Arseniy Ivanov)

## 2.0.0
- adding connection_pool for handle apple sockets
- removing resque hard dependency
- adding support for sending sync messages
- adding Thread support
- adding support to sidekiq (Caue Guerra)
- truncation messages when payload is greater than 256 option (Caue Guerra)

# Version 1.0
## 1.0.6
- Added support for password-protected .pem files
- Read feedback data in 38-byte chunks
- Support passing dictionary as :alert key
- Logging to STDOUT if no other loggers present
