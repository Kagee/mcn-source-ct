# mcn-source-ct

Part of my [MCN](https://github.com/search?q=user%3AKagee+mcn+in%3Aname&type=Repositories) (make clean no)-project.

Scripts for downloading and extracting .no domains from certificate transparency logs.

1. build https://github.com/google/certificate-transparency per instructions
2. Install ABSL: sudo pip2 install absl-py•
3. build python protobuf bindings? in ct/protobuf/python using "python setup.py build"
4. Set relevant paths in config.sh
5. Get certificates using get_certs.sh
6. List uniqe .no-domains using list_domains.sh
