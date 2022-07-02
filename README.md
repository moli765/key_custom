# 基于P3TERX大佬的key.sh修改，增加了部分参数
## 增加 -c -s ：

## -c 简要说明
|  参数   | 说明  |
|  ----  | ----  |
| set pub key and overwrite | #强制写入line：49的的公钥，与 -s 唯一区别|
| disable_password |  #关闭密码登录 |
| ClientAliveInterval=60 & ClientAliveCountMax=720 | #连接保活，60s一次，可保持连接12h |
| MaxAuthTries=3 | #最大尝试次数为3,默认20 |
| PermitRootLogin=yes | #允许root登录,默认no |
| GSSAPIAuthentication=no | #设置no可加速SSH登录，部分系统默认为no |

## 使用说明 
### 用法一：写死公钥
1. fork仓库,修改key_custom.sh内公钥（line：49 引号内修改）
2. 终端内执行
#### bash <(curl -fsSL https://raw.fastgit.org/你的github ID/key_custom/main/key_custom.sh) -c
- tips：https://raw.fastgit.org/你的github ID/key_custom/main/key_custom.sh 太长，可使用短链接缩短 ，如小马短链接
### 用法二：按原作者用法 增加 -s 即可
#### bash <(curl -fsSL https://sourl.cn/GGw9rg) -og 你的github名 -s
