#/bin/bash
python -c "import dimond"
if [ "$?" != 0 ];
   then
   echo "Module dimond not installed, proceeding..."
   pip install dimond --no-dependencies
   sed 's/bluepy_mjg59/bluepy/g' /usr/local/lib/python3.9/site-packages/dimond/__init__.py > /usr/local/lib/python3.9/site-packages/dimond/__init__.py
   echo "Installation completed, rebooting"
   reboot
   else
   echo "Module correctly installed!"
fi