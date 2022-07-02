# key_custom
## 基于P3TERX大佬的脚本修改，增加了部分参数
### -c 设置如下：
Costume settings:
- set pub key and overwrite
- PermitRootLogin=yes 
- PasswordAuthentication no
- UserDNS=no 
- GSSAPIAuthentication=no
- MaxAuthTries=3 
- ClientAliveInterval=60  
- ClientAliveCountMax=720
     
### 便于个人使用，可直接写死pub key，line：49 引号修改即可
set_pub_key(){
    PUB_KEY="这里填公钥，不用主机名"

### 一键操作
bash <(curl -fsSL git.io/key.sh) -c
