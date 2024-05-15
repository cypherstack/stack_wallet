# Configure Linux for Duo.
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../../linux/CMakeLists.txt
sed -i 's/Stack Wallet/Stack Duo/g' ../../linux/my_application.cc
