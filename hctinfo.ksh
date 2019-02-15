#!/usr/bin/ksh
#  Script:              hctinfo.ksh
#  Instance:            1
#  %version:            1 %
#  Description:
#  %created_by:         David Lyons %
#  %date_created:       Wed Sep  13 16:35:38 EDT 2006 %


################################################
#
#  Prints various information for a DHCT
#  identified by its MAC address:
#
#  a ) Admin status
#  i ) OS Image
#  g ) Group
#  d ) Description
#  m ) QPSK Mod
#  o ) Operational status
#  p ) Packages
#
################################################


usage()
{
        printf "Usage: %s [-a|A] [-d|D] [-i|I] [-g|G] [-h|H] [-m|M] [-o|O] [-p|P] hct_mac_address ...\n" $0
}
help()
{
        usage
        printf "\nOptions\n\ta|A: prints ADMIN STATUS\n\ti|I: prints OS IMAGE\n\tg|G: prints dhct GROUP\n\td|D: prints dhct DESCRIPTION\n\tm|M: prints MOD/DEMO
D\n\to|O: prints OPERATIONAL STATUS\n\tp|P: prints PACKAGES\n\th|H: HELP\n\thct_mac_address: The MAC address of the DHCT\n"
}

getAdminStatus()
{
        ADMSTAT=$(dbaccess dncsdb - << ! 2>/dev/null |\
                sed -e 's/hct_admin_status//'
		SET isolation dirty read;
                SELECT hct_admin_status from hct_profile where hct_mac_address="${1}";
! )
        if [ ${ADMSTAT} -eq 1 ] 2>/dev/null
        then
                printf "  1. Out Of Service\n"
                return 0
        fi
        if [ ${ADMSTAT} -eq 2 ] 2>/dev/null
        then
                printf "  2. In Service 2-Way\n"
                return 0
        fi
        if [ ${ADMSTAT} -eq 3 ] 2>/dev/null
        then
                printf "  3. Deployed\n"
                return 0
        fi
        if [ ${ADMSTAT} -eq 4 ] 2>/dev/null
        then
                printf "  4. In Service 1-Way\n"
                return 0
        fi
        printf "  ## NO ADMIN STATUS ##\n"
}

getOperStatus()
{
        OPERSTAT=$(dbaccess dncsdb - << ! 2>/dev/null |\
                sed -e 's/hct_oper_status//'
		SET isolation dirty read;
                SELECT hct_oper_status from hct_profile where hct_mac_address="${1}";
! )
        if [ ${OPERSTAT} -eq 1 ] 2>/dev/null
        then
                printf "  1. Unknown\n"
                return 0
        fi
        if [ ${OPERSTAT} -eq 2 ] 2>/dev/null
        then
                printf "  2. MAC_Init_Failed\n"
                return 0
        fi
        if [ ${OPERSTAT} -eq 3 ] 2>/dev/null
        then
                printf "  3. MAC_Initialized\n"
                return 0
        fi
        if [ ${OPERSTAT} -eq 4 ] 2>/dev/null
        then
                printf "  4. DSMCC_Boot_failed\n"
                return 0
        fi
        if [ ${OPERSTAT} -eq 5 ] 2>/dev/null
        then
                printf "  5. Active\n"
                return 0
        fi
        if [ ${OPERSTAT} -eq 6 ] 2>/dev/null
        then
                printf "  6.\n"
                return 0
        fi
        if [ ${OPERSTAT} -eq 7 ] 2>/dev/null
        then
                printf "  7.\n"
                return 0
        fi
        printf "  ## NO OPERATIONAL STATUS ##\n"
}

getDescription()
{
        DESCRIPTION=$(dbaccess dncsdb - << !  2>/dev/null|\
                sed -e 's/hctt_description//' -e '/^$/ d'
		SET isolation dirty read;
                SELECT hct_type.hctt_description
                FROM hct_type,hct_profile
                WHERE hct_type.hctt_id=hct_profile.hctt_id
                AND hct_type.hctt_revision=hct_profile.hctt_revision
                AND hct_type.hctt_oui=hct_profile.hctt_oui
                AND hct_profile.hct_mac_address="${1}";
! )
        printf "%s\n" "${DESCRIPTION:-  ## NO DESCRIPTION ##}"
}

getImage()
{
        IMG=$(dbaccess dncsdb - << ! 2>/dev/null|\
	sed -e 's/description//' -e '/^$/d'
		SET isolation dirty read;
                SELECT  pd_os_image.description
                FROM    pd_os_image,pdosassociation,pdoshct,pd_os_hct_type,hct_profile
                WHERE   pdoshct.hctmacaddress="${1}"
                AND     hct_profile.hct_mac_address=pdoshct.hctmacaddress
                AND     pd_os_hct_type.typeid=hct_profile.hctt_id
                AND     pd_os_hct_type.revision=hct_profile.hctt_revision
                AND     pdosassociation.hardwareid=pd_os_hct_type.hardwareid
                AND     pdosassociation.groupid=pdoshct.groupid
                AND     pd_os_image.imageid=pdosassociation.imageid;
! )
        if [ -z "${IMG}" ]
        then
        IMG=$(dbaccess dncsdb - << ! 2>/dev/null|\
        sed -e 's/description//' -e '/^$/d'
		SET isolation dirty read;
                SELECT  pd_os_image.description
                FROM    pd_os_image,pdosassociation,pd_os_hct_type,hct_profile
                WHERE   hct_profile.hct_mac_address="${1}"
                AND     pd_os_hct_type.typeid=hct_profile.hctt_id
                AND     pd_os_hct_type.revision=hct_profile.hctt_revision
                AND     pdosassociation.hardwareid=pd_os_hct_type.hardwareid
                AND     pdosassociation.groupid=0
                AND     pd_os_image.imageid=pdosassociation.imageid;
! )
        fi
        printf "%s\n" "${IMG:-  ## NO IMAGE ##}"
}

getGroup()
{
        typeset -i GRPID
        GRPID=$(dbaccess dncsdb - << !  2>/dev/null|\
        sed 's/groupid//'
		SET isolation dirty read;
                SELECT groupid
                FROM pdoshct
                WHERE hctmacaddress="${1}";
! :-0)
        if [ ${GRPID} -gt 0 ]
        then
                dbaccess dncsdb - << ! 2>/dev/null |\
                sed -e 's/description//' -e '/^$/d'
			SET isolation dirty read;
                        SELECT pdosgroup.description
                        FROM pdosgroup,pdoshct
                        WHERE pdosgroup.groupid=pdoshct.groupid
                        AND pdoshct.hctmacaddress="${1}";
!
        else
                printf "  default\n"
        fi
}

getMod()
{
        QMOD_NAME=$(dbaccess dncsdb - << !  2>/dev/null|\
                        sed -e '/qmod_name/d' -e '/^$/ d'
				SET isolation dirty read;
                                SELECT davic_qpsk.qmod_name
                                FROM davic_qpsk,hct_profile
                                WHERE davic_qpsk.qmod_modem_id=hct_profile.hct_qpsk_mod_id
                                AND hct_profile.hct_mac_address="${1}";
! )
#       echo ${QMOD_NAME}
        printf "  %s\n" "${QMOD_NAME:-## NO QPSK ##}"
}

getPackages()
{
        PKGS=$(dbaccess dncsdb - << ! 2>/dev/null |\
        sed -e '/pkg_name/d' -e '/^$/d'
		SET isolation dirty read;
                SELECT  sm_pkg_auth.pkg_name
                FROM    sm_pkg_auth,hct_profile
                WHERE   hct_profile.hct_mac_address="${1}"
                AND     sm_pkg_auth.sm_serial_num=hct_profile.hct_se_serial_num;
! )
        printf "  %s\n" ${PKGS:-"## NO PACKAGES ##"}
}

### BEGIN main()

ADMIN_STAT=0
GROUP=0
IMAGE=0
DESC=0
MOD=0
OPER_STAT=0
PACKS=0
while getopts :aAdDhHiIgGmMoOpP name
do
        case ${name} in
        a|A)    ADMIN_STAT=1;;
        i|I)    IMAGE=1;;
        g|G)    GROUP=1;;
        d|D)    DESC=1;;
        m|M)    MOD=1;;
        o|O)    OPER_STAT=1;;
        p|P)    PACKS=1;;
        h|H)    help
                exit 1;;
        ?)      printf "\nWTF? Way to go, dumbass.\n\n"
                usage
                exit 1;;
        esac
done

shift $(($OPTIND - 1))

if [ $# -lt 1 ]
then
        printf "\nWhere's the MAC address, pinhead?\n\n"
        usage
        exit 1
fi

# MACs are stored in the database as an uppercase string with colons.
# But this script doesn't check for colons.
typeset -u MAC

for MAC in "$@"
do
        [ ${#} -gt 1 ]		&& printf "\n%s\n" ${MAC}
        [ ${DESC} -eq 1 ]	&& getDescription ${MAC}
        [ ${ADMIN_STAT} -eq 1 ]	&& getAdminStatus ${MAC}
        [ ${OPER_STAT} -eq 1 ]	&& getOperStatus ${MAC}
        [ ${IMAGE} -eq 1 ]	&& getImage ${MAC}
        [ ${GROUP} -eq 1 ] 	&& getGroup ${MAC}
        [ ${MOD} -eq 1 ]	&& getMod ${MAC}
        [ ${PACKS} -eq 1 ]	&& getPackages ${MAC}
done

### END main()
