#!/bin/bash 
# 首先判断有没有安装程序,有继续，没有退出脚本提示用户安装
check_apps()
{
local apps=`dpkg -l | grep "jpegoptim"`
if [[ "$apps" != ""  ]]; then
        #安装
        return 1                                                                   
    fi
        return 0
}    
check_apps
if [ $? -eq 0 ]; then 
    echo "应用未安装,请手动安装"
    echo "apt install jpegoptim"
    exit -1
fi
# 进入工作目录
# ！！！！不要照抄这里不同的手机需要更改下！！！！
cd /data/data/com.termux/files/home/storage/dcim/Camera

# 查看文件夹中有没有时间戳文件
timer_file=.jpegoptim.timer    
    if [ ! -f "$timer_file" ]; then
        echo "本次为全新压缩，将压缩所有照片可能会处理较长时间，请耐心等待，不要强制退出"
        # 建立一个很早的时间戳文件用作后面的比较
        touch -t 200001010000.00 .jpegoptim.timer                       
    else
    # 显示出上一次的压缩时间
        file_time=`stat .jpegoptim.timer | grep "Modify" | awk '{print $2}'`
        echo "上次压缩是在 ${file_time}"
        echo "本次仅压缩 ${file_time} 之后的照片"
fi
# 然后分析文件夹中需要处理的文件数量、压缩前大小、预计的时间
# 任意键继续函数
get_char()
{
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
number=`find ./ \( -iname '*.jpeg' -o -iname '*.jpg' \) -newer .jpegoptim.timer -type f | wc -l`
size_befor=`find ./ \( -iname '*.jpeg' -o -iname '*.jpg' \) -newer .jpegoptim.timer -type f | xargs du -ch | grep total | awk '{print $1}'`
size_befor_dir=`du -ch | grep total | awk '{print $1}'`
if [ ${number} -eq  0 ]; then 
    echo "搜索中······ "
    echo "本次没有要处理的照片，脚本退出"
    exit -1
fi
echo "当前目录总大小为：${size_befor_dir}"
echo "本次要压缩的照片数量为：${number} ，大小为：${size_befor}"
# 暂停，用户选择继续
echo "按任意键继续"
echo "按 CTRL+C 结束" 
char=`get_char`
# 进行处理，结束后展示压缩后大小、然后删除时间戳，创建新的时间戳文件、
echo "处理中···请不要强行退出"
find ./ \( -iname '*jpeg' -o -iname '*jpg' \) -newer .jpegoptim.timer  -type f -exec  jpegoptim  --preserve --max=80  --quiet '{}' \;  
size_after=`find ./ \( -iname '*.jpeg' -o -iname '*.jpg' \) -newer .jpegoptim.timer -type f | xargs du -ch | grep total | awk '{print $1}'`
size_after_dir=`du -ch | grep total | awk '{print $1}'`
echo "压缩完成，压缩后的大小为：${size_after}"
echo "压缩后的目录总大小为：${size_after_dir}"
# 更新时间戳文件
rm .jpegoptim.timer && touch .jpegoptim.timer
exit -1
