#!/bin/bash

function deploy() {
    imageName="zerotier-planet"

    # 处理ip信息
    curr_ip=$(curl -s cip.cc | grep http | awk -F '/' '{print $4}')

    echo "-------------------------------------------"
    echo "支持使用域名或者ip，默认端口为9993，暂不支持修改"
    echo "请输入 ip 或者 域名"
    echo ""
    echo "您当前公网ip为："$curr_ip",使用当前ip请输入:y"
    echo "-------------------------------------------"

    ip=""
    read c

    if [ "$c" = 'y' ]; then
        ip=$curr_ip
    else
        ip=$c
    fi

    echo "----------------------------"
    echo "部署的ip为:$ip, 是否继续? y/n"
    read or
    if [ "$or" = "y" ]; then
        echo "{
  \"stableEndpoints\": [
    \"$ip/9993\"
  ]
}
" >./patch/patch.json
    else
        exit -1
    fi

    # 开始安装程序
    echo "清除原有内容"
    rm /opt/planet
    docker stop $imageName
    docker rm $imageName
    docker rmi $imageName

    echo "打包镜像"
    docker build --network host -t $imageName .

    echo "启动服务"
    for i in $(lsof -i:9993 -t); do kill -2 $i; done
    docker run -d --network host --name $imageName --restart unless-stopped $imageName
    docker cp $imageName:/app/bin/planet /opt/planet
}

function export() {
    docker exec $imageName bash -c "cd /var/lib/ && tar -zcvf zerotier-one.tar.gz zerotier-one/"
    docker cp $imageName:/var/lib/zerotier-one.tar.gz ./backup

    docker exec $imageName bash -c "cd /opt/ && tar -zcvf ztncui.tar.gz ztncui/"
    docker cp $imageName:/opt/ztncui.tar.gz ./backup

    echo "导出成功"
    echo "配置放在./backup目录下"
}

function import() {
    docker cp ./data/zerotier-one.tar.gz $imageName:/var/lib/
    docker exec $imageName bash -c "cd /var/lib/ && rm -rf zerotier-one && tar -zxvf zerotier-one.tar.gz"

    docker cp ./data/ztncui.tar.gz $imageName:/opt/
    docker exec $imageName bash -c "cd /opt/ && rm -rf ztncui && tar -zxvf ztncui.tar.gz"

    docker restart $imageName

    echo "导入成功"
}

func build_plant(){

}

function menu() {
    echo
    echo "=============功能菜单============="
    echo "| 1 - 安装"
    echo "| 2 - 导出配置（需要先正确安装）"
    echo "| 3 - 导入配置（需要先安装）"
    echo "| 4 - 重新生成planet文件"
    echo "| q - 退出"
    echo "---------------------------------"
    printf "请选择菜单："
    read -n 1 n
    echo
    if [[ "$n" = "1" ]]; then
        echo "安装"
        deploy

    elif [ "$n" = "2" ]; then
        echo "导出配置"
        export
    elif [ "$n" = "3" ]; then
        echo "导入配置"
        import
    elif [ "$n" = "q" ]; then
        echo 退出
        return
    else
        echo "错误选项"
    fi
}
menu
