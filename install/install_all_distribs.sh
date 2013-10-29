#!/bin/bash
# This script installs an SAP Sybase product in the current environement.
# It does not create an instance of any server, it justs executes 
# setup.bin into the right folder

# Distribution files are often untared into a specific filesystem mounted on /sybase
#  /sybase/<PRODUCT>/<ebf version>/
#  For instance /sybase/ASE157/ebf21456/

. /etc/bash.bashrc

main() {

   find /sybase -name setup.bin | grep -v sysam | while read setup_file ; do

      printLog "Found ${setup_file}" 
      ebf_dir=$(dirname ${setup_file} )
      printLog "   EBF dir is : ${ebf_dir}"
      PRODUCT=$( basename $(dirname ${ebf_dir} ) )
      printLog "   PRODUCT  is : ${PRODUCT}"
      #attempts to locate an template resource file, sometimes it is alongside
      res_file=${ebf_dir}/sample_response.txt
      [[ ! -f ${res_file} ]] && res_file=${ebf_dir}/installer.properties
      [[ ! -f ${res_file} ]] && printLog "   No sample resource file, skipping" && continue
      
      sedexp=$(grep -v "^#" ${HOME}/install/replace_answers.txt | \
        awk -F "#" '{ print "s#^" $1 ".*#" $1 " " $2 "#;"'}  | tr -d "\n" )

      sed -e "${sedexp}" ${res_file} > ${HOME}/install/install_${PRODUCT}.rs
  
       #Install distrib
       printLog "Executing resource file ${HOME}/install/install_${PRODUCT}.rs"
       export SYBASE=/sybase/${PRODUCT}
       ${setup_file} -i silent -f ${HOME}/install/install_${PRODUCT}.rs -DAGREE_TO_SYBASE_LICENSE=true > ${HOME}/install/install_${PRODUCT}.log 2>&1

       #Remove installation files
       [[ $? -eq 0 ]] && printLog "${PRODUCT} installed ! removing setup files ${ebf_dir}" && rm -rf ${ebf_dir} 
       
   done
   
   #Install SP01.LP03
   printLog "Applying patch IQ 16 SP01.LP03"
   cp -r /sybase/IQ16/ebf21738/iq1600_sp01.03/* /sybase/IQ16/IQ-16_0
   [[ $? -eq 0 ]] && rm -rf /sybase/IQ16/ebf21738/iq1600_sp01.03
   cp -r /sybase/IQ16/ebf21738/scciq-3_2/* /sybase/IQ16/SCC-3_2/plugins
   [[ $? -eq 0 ]] && rm -rf /sybase/IQ16/ebf21738/scciq-3_2
   
   #Add a terminal shortcut to the desktop
   printLog "Adding a terminal shortcut to the desktop"
   mkdir -p /home/sybase/Desktop
   chmod 777 /home/sybase/Desktop
   if [ -r /usr/share/applications/gnome-terminal.desktop ]; then
      cp /usr/share/applications/gnome-terminal.desktop /home/sybase/Desktop
      chmod 755 /home/sybase/Desktop/gnome-terminal.desktop
   fi
    

   #creates a random sa password for various products
   md5sum /proc/stat | cut -c 2-12 > /home/sybase/.pass
   chmod 600 /home/sybase/.pass
   
   #creates a random sa password for various products
   md5sum /proc/stat | cut -c 3-13 > /home/sybase/.repli
   chmod 600 /home/sybase/.repli
   
   return 0
}

printLog(){
   echo ${1} | tee -a ${HOME}/install/install_all_distribs.log
}

main 

exit 0
