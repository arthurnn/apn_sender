# Version 2.0
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
