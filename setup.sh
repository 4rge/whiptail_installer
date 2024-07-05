#!/usr/bin/env bash

## Check for root privelage else exit
test "$EUID" -ne 0 && \
whiptail --msgbox --clear --title "Error" --ok-button "Exit" "Please run as sudo or root" 0 0 && \
exit || :

: ${PKGMGMT:="apt"} ## If no package manager selected, default to apt

## Help menu
function helpMenu() {
  whiptail --msgbox --title "$(basename "${0}")" \
  "A TUI installer for various system packages. \n \ 
  Syntax: $(basename ${0}) [-p|-pkg <package-manager>] [-n|-no]\n\n \
  Options: \n \
  -p)  Set the package manager \n \
  -h)  Launch this menu \n \
  -n)  No inital update" 0 0
}

## Provides the percentage gauge during install
function Module() {
{

## Generates a percentage value that each package is worth based on total number of packages to be installed
INC="$( echo $((100/"$(echo ${LIST} | wc | awk '{print $2}')")))"

## Loop over the $LIST and run the appropriate commands
for PKG in ${LIST} ; do
    sleep 0.5
    COMMAND="${PKGMGMT} ${ACTION} ${PKG} -y" ## The main command to edit, changes which command gets looped over
    echo -e "XXX\n${PER}\n${PKG}... \nXXX" ## Show pre-command percentage
    test "${COMMAND}" && eval "${COMMAND}" 2> /dev/null && TEST="Pass" || TEST="Fail" ## Test the command, do or die
    PER=$(( $PER + $INC )) ## Calculate the current percentage
    echo -e "XXX\n${PER}\n${PKG}... Done: ${TEST}.\nXXX" ## Show post-command percentage
    sleep 0.5
done
LIST="" ## Clear the $LIST variable for next round
} | whiptail --title "${PKGMGMT} ${ACTION}" --gauge "Please wait while ${ACTION} in progress" 6 60 0
}

## Searches for all packages for common "Provides" in apt cache
function basePackages() {
  while [ 1 ] ; do

##  Parse CHOICE variable to determine which list to use
    case ${CHOICE} in
      "1") LIST="${XDISP} ${XWIND} ${XTERM} ${CCOMP} ${CROND} ${SPEEC} ${WORDL} ${SSHSE} ${SSHAS} ${XSERV} ${VNCSE} ${HTTPD}" ;;
      "2") LIST="${IRC} ${INFOB} ${PDFVI} ${NEWSR} ${MPDCL} ${DICTCL} ${MAILR} ${EDITO} ${WWWBR} ${VNCVI}" ;;
    esac

## Parse MENU options and list the available packages in each Provides selection then store it as a variable
    eval PACKAGE=$(whiptail --menu --notags --clear --ok-button "Select" --cancel-button "Submit" --backtitle "${LIST}" "Select Package Type:" 16 100 8 "${MENU[@]}" 3>&1 1>&2 2>&3)
    AVAILABLE="$(IFS=" " ; \
    echo "$(apt-cache showpkg ${PACKAGE} | awk '/Pa/, /Reverse P/ {next} {print $1 | "sort"}' | uniq)")"
    test -z $PACKAGE && break || :

## List above mentioned variables and promp user to input selection
    eval SELECTION=("$(whiptail --inputbox --clear --scrolltext --title "Select ${PACKAGE}" "${AVAILABLE}" 16 100 3>&1 1>&2 2>&3)")    

## Generate dynamic variable names based off menu input
    DYNAME="$(echo ${PACKAGE} | sed 's/-//g' | cut -c1-5 | tr '[a-z]' '[A-Z]')"
    export "${DYNAME}"="${SELECTION}"

    test ${?} = 0 && : || break ## Check exit codes are fine
  done
}

## Launch the primary menu and hold until selected by user
function mainMenu() {
  while [ 1 ] ; do

## List available main menu options and pass critical arguments along script
  CHOICE=$(whiptail --title "Main Menu" --notags --clear --cancel-button "Exit" --ok-button "Select" --menu "Make your choice" 16 100 8 \
	"1" "Install System Packages" \
	"2" "Install User Packages" \
        "3" "Purge Unnecessary Packages"	3>&2 2>&1 1>&3)

  case ${CHOICE} in

## Install admin based applications
	"1")   MENU=("x-display-manager" "Login Manager" \
    			"x-window-manager" "Window Manager" \
    			"x-terminal-emulator" "Terminal" \
    			"c-compiler" "Additional Compilers" \
    			"cron-daemon" "Cron" \
    			"speech-dispatcher-*:i386" "Text To Speech Engine" \
    			"wordlist" "Additional Language Support" \
    			"ssh-server" "SSH-Server" \
    			"ssh-askpass" "SSH-Askpass" \
    			"xserver" "Xserver" \
    			"vnc-server" "VNC Server" \
    			"httpd" "Web Server")
		basePackages
		ACTION="install"
	        Module && mainMenu ;;

## Install user based applications
	"2")   MENU=("irc" "Chat Client" \
    			"info-browser" "Info Browser" \
    			"pdf-viewer" "PDF viewer" \
    			"news-reader" "RSS Reader" \
    			"mpd-client" "Music Player" \
    			"dict-client" "Dictionary Client" \
    			"mail-reader" "Email Reader" \
    			"editor" "Editor" \
    			"www-browser" "Web Browser" \
    			"vnc-viewer" "VNC Viewer")
		basePackages
		ACTION="install"
		Module && mainMenu ;;

## Remove unneded bloat
	"3")   LIST="x11-apps mc"
		ACTION="purge"
		Module && mainMenu ;;

  esac
  test ${?} = 1 && : || break ## Check if cancel button is pressed and if it is exit cleanly
  done
}

## Handle CLI arguments passed to the script
while getopts ":hp:n" option; do
   case ${option} in
      h|help) helpMenu ; exit ;;
      p|pkg) PKGMGMT="${OPTARG}" ;;
      n|no) SKIP="True" ;;
   esac
:
done

test "${SKIP}" != "True" && printf "\033[0;32mUpdating\033[0m\n" && whiptail --msgbox "$(${PKGMGMT} update 2> /dev/null | tail -1)" 0 0 || : ## Update unless the "no" flag is called then skip
test mainMenu && mainMenu || echo "${?}" ## Make sure the script can run cleanly, then do or echo the error code
