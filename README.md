# mcn-source-ct

Part of my [MCN](https://github.com/search?q=user%3AKagee+mcn+in%3Aname&type=Repositories) (make clean no)-project.

Scripts for downloading and extracting .no domains from certificate transparency logs.

1. build https://github.com/google/certificate-transparency per instructions
2. Install requests, pip, jq: sudo apt-get install jq python-pip python-requests
3. Install ABSL: sudo pip2 install absl-py
4. build python protobuf bindings? in ct/protobuf/python using "python setup.py build"
5. Set relevant paths in config.sh
6. Run patch_disable_https_verify.sh to patch out HTTPS verification
7. Get list of logs with ./make_loglist.sh
8. Get certificates using get_certs.sh
9. List uniqe .no-domains using list_domains.sh
