#!/bin/bash

. /etc/bash.bashrc

main() {

   ###
   ###  ebf or distrib files must be extracted at a specific location
   ###  /sybase/PRODUCT/ebfversion/
   find /sybase -name setup.bin | grep -v sysam | while read setup_file ; do

      printLog "Found ${setup_file}" 
      ebf_dir=$(dirname ${setup_file} )
      printLog "   EBF dir is : ${ebf_dir}"
   
      PRODUCT=$( basename $(dirname ${ebf_dir} ) )
      printLog "   PRODUCT  is : ${PRODUCT}"
   
      res_file=${ebf_dir}/sample_response.txt
      [[ ! -f ${res_file} ]] && res_file=${ebf_dir}/installer.properties
      [[ ! -f ${res_file} ]] && printLog "   No sample resource file, skipping" && continue
   
      sed -e "s:USER_INSTALL_DIR=.*:USER_INSTALL_DIR=/sybase/${PRODUCT}:" \
	      -e 's/SY_CONFIG_ASE_SERVER=true/SY_CONFIG_ASE_SERVER=false/' \
          -e 's/SY_CONFIG_BS_SERVER=true/SY_CONFIG_BS_SERVER=false/'   \
          -e 's/SY_CONFIG_XP_SERVER=true/SY_CONFIG_XP_SERVER=false/'   \
          -e 's/SY_CONFIG_JS_SERVER=true/SY_CONFIG_JS_SERVER=false/'   \
          -e 's/SY_CONFIG_SM_SERVER=true/SY_CONFIG_SM_SERVER=false/'   \
          -e 's/SY_CONFIG_WS_SERVER=true/SY_CONFIG_WS_SERVER=false/'   \
          -e 's/SY_CONFIG_SCC_SERVER=true/SY_CONFIG_SCC_SERVER=false/'   \
          -e 's/SYSAM_NOTIFICATION_ENABLE=.*/SYSAM_NOTIFICATION_ENABLE=false/' \
		  -e 's/START_SCC_SERVER=.*/START_SCC_SERVER=no/' \
		  -e 's/CONFIG_SCC_CSI_SCCADMIN_PWD=.*/CONFIG_SCC_CSI_SCCADMIN_PWD=SAPSYBASE/' \
		  -e 's/CONFIG_SCC_CSI_UAFADMIN_PWD=.*/CONFIG_SCC_CSI_UAFADMIN_PWD=SAPSYBASE/' \
		  -e 's/USER_INPUT_RESULTS:.*/USER_INPUT_RESULTS: \\"Oracle\\",\\"\\",\\"\\"/' \
          ${res_file} > /sybase/install_${PRODUCT}.rs

   	   #Install distrib
       printLog "Executing resource file /sybase/install_${PRODUCT}.rs"
	   export SYBASE=/sybase/${PRODUCT}
       ${setup_file} -i silent -f /sybase/install_${PRODUCT}.rs -DAGREE_TO_SYBASE_LICENSE=true > /sybase/install_${PRODUCT}.log 2>&1

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
   echo ${1} | tee -a /sybase/install.log
}

main 

exit 0
