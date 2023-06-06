# Secure Messenger

## What is it?

Secure messenger is a multi-platform communicator written with Flutter framework in Dart language. Its purpose is to ensure secure communication, including sending and receiving text messages and files, over unnecessarily secure network.

## How does it work?

In order to ensure ensure security mechanisms of asymmetric and symmetric cryptography were used. Let's look at the application operations in a few steps:

### 1. Registration, login and RSA key pair generation

When you first launch the application, you have to register. During registration you'll provide username and password. After that, assuming that login and password are valid, RSA key pair will be generated and saved on your device. Due to the importance of keeping private key safe, it won't be saved like a plaintext. It will be encrypted with AES cipher in CBC mode, where encryption key is a hash (generated using SHA) of user's password. The hash is also used as a seed in random generator which generates initialization vector for AES.
After that application will load these keys and you'll be able to use the application.

If you already have an account you can login using your credentials. Application will then verify you username and password, trying to decrypt private key with hash of the password that you've provided. If it succeeds, keys will be loaded and you'll also be able to use the application.

### 2. Initial connection initialization

After successful registration or login you'll be able to choose your network interface and IP address assigned to it, which in other words means that you can choose a network in which you'd like to communicate.

Then, you can choose to either initialize new connection or listen for incoming connection (in case someone tries to connect with you).

We based our communication on client-server architecture with TCP protocol and we're using sockets for communication. If you choose to listen for connection then you'll become a server which wait for a client to connect. You'll see waiting screen with IP on which you're listening to. If the other user will initialize connection with you, handshake will be performed. On the other hand, if you'd like to initialize a connection, you'll be asked to provide an IP address of a person that you'd like to connect to and the cipher mode (CBC or ECB) which you'd like to use. Keep in mind that you have to choose the same network in order to connect!

### 3. Handshake mechanism

Handshake mechanism is crucial when it comes to secure key exchange and establishing connection.
After establishing socket connection described in the previous section, proper connection initialization. 
Assuming that the UserA initialized the connection, thus he's the client and the UserB is the server, handshake is given:
- UserA sends unencrypted message "SYN"
- UserB receives unencrypted message "SYN" and responds with unencrypted message "SYN-ACK"
- UserA receives unencrypted message "SYN-ACK" and responds with unencrypted message "ACK"
- UserB receives unencrypted message "ACK" and responds with his unencrypted public key
- UserA receives UserB's unencrypted public key
- UserA generates session key with a pseudorandom generator. He joins the parameters of the cipher (algorithm type (as for now we're only using AES), initial vector (also generated randomly), key size, block size, cipher mode) combine them into so called Client Package, encrypts whole package with UserB's public key and sends it.
- UserB receives encrypted message and decrypts it with his private key. He configure his encrypter (container wrapping cipher algorithm) based on the received package of data. Then he encrypts "DONE" message with the session key.
- UserA receives encrypted "DONE" message, he decrypts it with the session key and responds with "DONE-ACK" message, also encrypted with the session key.
- UserB receives "DONE-ACK" message encrypted with the session key and decrypts it. From now on handshake is finished and regular and secure communication can be performed.

Keep in mind that described steps assumed that there were no problems whatsoever during the handshake. In reality, if they occur, appropriate message will be displayed.


### 4. Regular communication

After passing previous steps you'll finally be able to send text messages and files in a secure way.
Regular communication uses AES algorithm with session key, which was previously securily exchanged over the network as was described in the previous section. It uses it for symmetric message encryption, as symmetric cryptography is faster than assymetric one and therefore more suitable for a communicator.
What is worth mentioning: you can send really large files using our communicator as we've implemented dividing data into fixed size packets, enrypting each one of them separately and sending over the network. You'll also see the progress of sending files. 
