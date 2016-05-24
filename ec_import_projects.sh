#!/bin/bash
#
# ec_import_projects.sh - deploy projects to an EC server
#

function echo_usage {
   cat <<END_OF_USAGE
Usage en_import_projects.sh [OPTION...] [PROJECT...]

  -b, --branch=BRANCH      deploy projects to USER_BRANCH, none by default
  -c, --script-mode        Assume yes to all user warning prompts, do not
                           prompt for commander login password
  -d, --dir=DIR            input dir for project files default is current
                           directory
  -e, --ec-force           force replacement of existing projects
  --emergency-force        Not intended for developer use. Override saftey
                           checks when importing. Intended for minimal manual
                           only use during Emergency Recovery. Do not use as
                           part of script or job step.
  -f, --flat               import from flat layout under DIR default is
                           layout specified by MANIFEST and SCM_CONF
  -h, --help               display this help list
  -m, --manifest=MANIFEST  MANIFEST is repo xml manifest file specifying
                           repo layout default is DIR/.repo/manifest.xml
  -n, --no-state           Do not import projects whose name ends in _State
                           Should always be used when importing to production
                           environment
  -o, --host=HOST          import projects on host.
                           env \$BAIT_SCM_COMMANDER_SERVER by default
  -r, --ref-projects=REF_PROJS
                           REF_PROJS is list of all projects where references to
                           these projects should be updated in the export.
                           default is all projects in SCM_CONF
  -s, --scm-conf=SCM_CONF  SCM_CONF is xml configuration file mapping commander
                           projects to git repos. if not provided env variable
                           BAIT_SCM_CONF_FILE is used
  -S, --ssh                Use ssh/scp to copy xml project files to local temp
                           dir on HOST for import. Default is to use temp dir
                           on network share
  -t, --production         DEPRECATED, same effect as --no-state
  -u, --user=USER          deploy projects as USER, env \$USER by default
                           \`none' sets user to none (i.e. no user name appended
                           projects)
  -v, --verbose            verbose output
  -x, --use-suffix         For compatibility with older versions of import/
                           export script. In this mode projects are in form
                           PROJECT_USER_BRANCH. For example:
                           Android_Common_gregt_scm_dev
                           Current versions of the projects are named in the
                           form USER_BRANCH_PROJECT
                           For example: gregt_scm_dev_Android_Common
  -z, --non-atomic         Do not use ec batch API to make all project updates
                           in an atomic commit to the ec database

  PROJECT... The EC projects to import. If null all projects in SCM_CONF are
             imported.

Report bugs to linux.bait.automation@qualcomm.com.
END_OF_USAGE
}

#Cannot use nounset due to some functions called with empty args
#set -o nounset
set -o errexit
set -o pipefail

# Parse command-line arguments.
LONG_OPTS="branch:,script-mode,dir:,ec-force,emergency-force,flat,help,"
LONG_OPTS+="manifest:,host:,no-state,non-atomic,ref-projects:,scm-conf:,ssh,"
LONG_OPTS+="produtcion,user:,verbose,use-suffix"

set +o errexit
# Parse command-line arguments.
TEMP=$(getopt -o b:cd:efhm:no:p:r:s:Stu:vxz \
       --long $LONG_OPTS -n $(basename $0) -- "$@")

if [ $? != 0 ] ; then echo "ERROR: getopt failed." >&2; exit 1 ; fi
set -o errexit

eval set -- "$TEMP"

# Defaults:
ATOMIC=1
CONFIG_FILE=tom.xml
DIR=$(pwd)
EC_FORCE=0
ECTOOL_LOGOUT_ON_CLEANUP=0
EMERGENCY_FORCE=0
FLAT_MODE=0
HOST="$BAIT_SCM_COMMANDER_SERVER"
INCLUDE_STATE=1
MANIFEST=
ORIG_WD=$(pwd)
PROJECTS=
REF_PROJECTS=
SANDBOX_BRANCH=
#See description for --use-suffix for sandbox naming conventions
SANDBOX_NAME_MODE='PREFIX'
SCM_USER=$USER
SCRIPT_MODE=0
SSH_MODE=0
VERBOSE=0

while true ; do
   case "$1" in
      -b|--branch) SANDBOX_BRANCH="$2" ; shift 2 ;;
      -c|--script-mode) SCRIPT_MODE=1 ; shift ;;
      -d|--dir) DIR="$2" ; shift 2 ;;
      -e|--ec-force) EC_FORCE=1 ; shift ;;
      --emergency-force) EMERGENCY_FORCE=1 ; shift ;;
      -f|--flat) FLAT_MODE=1 ; shift;;
      -h|--help) echo_usage ; exit 0 ;;
      -m|--manifest) MANIFEST="$2" ; shift 2 ;;
      -n|--no-state|-t|--production) INCLUDE_STATE=0; shift ;;
      -o|--host) HOST="$2" ; shift 2 ;;
      -r|--ref-projects) REF_PROJECTS="$2" ; shift 2;;
      -s|--scm-conf) CONFIG_FILE="$2" ; shift 2;;
      -S|--ssh) SSH_MODE=1 ; shift ;;
      -u|--user) SCM_USER="$2" ; shift 2 ;;
      -v|--verbose) VERBOSE=1 ; shift ;;
      -x|--use-suffix) SANDBOX_NAME_MODE='SUFFIX' ; shift ;;
      -z|--non-atomic) ATOMIC=0 ; shift ;;
      --) shift ; break ;;
      *) echo "Unrecognized option $1" >&2 ; exit 1 ;;
   esac
done

PROJECTS="$*"

re="^[Nn][Oo][Nn][Ee]$"
if [[ $SCM_USER =~ $re ]] ; then
    SCM_USER=""
    [ $VERBOSE -ge 1 ] && echo "Setting to empty USER"
fi

SCRIPT_NAME=$0

while [ -L $SCRIPT_NAME ] ; do
   SCRIPT_NAME=$(readlink $SCRIPT_NAME)
done

SCRIPT_NAME=$(basename $SCRIPT_NAME)

SCRIPT_FQ=$(/usr/sbin/lsof -p $$ | grep -E "/$SCRIPT_NAME([[:space:]]|$)" |
            awk '{print $9}')

SCRIPT_PATH=$(dirname $SCRIPT_FQ)

#if ! source $SCRIPT_PATH/import_export_lib.sh ; then
#    echo "Failed to source import_export_lib.sh" >&2
#    exit 1;
#fi

#get_config_file $CONFIG_FILE
CONFIG_FILE=$_CONFIG_FILE

#get_manifest_file_fq  $DIR $MANIFEST
MANIFEST=$_MANIFEST_FILE

[ -d $DIR ] || die "dir $DIR does not exist"

#check_host $HOST
HOST=$_HOST

SSH_OPTS=""
[ $SCRIPT_MODE -eq 1 ] && SSH_OPTS="-o 'BatchMode yes'"

#Default is 'PREFIX'
#if [ "$SANDBOX_NAME_MODE" == 'SUFFIX' ] ; then
#    get_prj_suffix "$SCM_USER" "$SANDBOX_BRANCH"
#    PRJ_SUFFIX="$_PRJ_SUFFIX"
#    PRJ_PREFIX=""
#else
#    get_prj_prefix "$SCM_USER" "$SANDBOX_BRANCH"
#    PRJ_PREFIX="$_PRJ_PREFIX"
#    PRJ_SUFFIX=""
#fi

#login_cmdr_host "$HOST" "$SCRIPT_MODE"

run_from_prj=$(ectool expandString '$[/myProject/projectName]' 2> /dev/null) ||
    run_from_prj='none'

#if [ $SSH_MODE -eq 0 ] ; then
#    get_tmp_paths
#    nix_tmp_path=$_nix_tmp_path
#    server_tmp_path=$_server_tmp_path
#fi

[ $VERBOSE -ge 1 ] && echo "\$[/myProject/projectName] = \`$run_from_prj'"

#Do not allow import to production server outside of BAIT_SCM_Privileged
#Hostname comparision may not be foolproof
#safety_check_production "$HOST" "$run_from_prj" $EMERGENCY_FORCE "Import"

#Safety check when importing 'bare' projects
#safety_check_bare_project "$PRJ_PREFIX" "$PRJ_SUFFIX" "$run_from_prj" \
                          $EMERGENCY_FORCE "Import"

#Safety check not to import _State projects on production
#Hostname comparision may not be foolproof
#safety_check_state_prj "$HOST" "$run_from_prj" $INCLUDE_STATE \
#                       $EMERGENCY_FORCE "Import"

#if [ -z "$PROJECTS" ] ; then
#    generate_project_list "$FLAT_MODE" "$DIR" "$CONFIG_FILE" \
#                          "$SCRIPT_PATH" $INCLUDE_STATE
#    PROJECTS=$_PROJECTS
#fi

#Die if --no-state given, but _State projects specified
#check_include_state $INCLUDE_STATE "$PROJECTS" "Import"

[ ! -z "$PROJECTS" ] || die "No valid projects to import"

#By default _State projects are included in REF_PROJECTS
if [ -z "$REF_PROJECTS" ] ; then
    generate_project_list "$FLAT_MODE" "$DIR" "$CONFIG_FILE" \
                          "$SCRIPT_PATH" 1
    REF_PROJECTS="$_PROJECTS"
fi

print_var_names="DIR FLAT_MODE EC_FORCE EMERGENCY_FORCE HOST INCLUDE_STATE "
print_var_names+="MANIFEST ORIG_WD PROJECTS REF_PROJECTS SANDBOX_BRANCH "
print_var_names+="SANDBOX_NAME_MODE SCM_USER SCRIPT_MODE SSH_MODE VERBOSE "
print_var_names+="nix_tmp_path server_tmp_path"

[ $VERBOSE -ge 1 ] && print_vars "$print_var_names"

for prj in $PROJECTS ; do
    get_repo_dir_for_prj "$prj" "$FLAT_MODE" "$CONFIG_FILE" \
                         "$SCRIPT_PATH" "$MANIFEST"
    prj_file="$DIR/$_REPO_DIR/$prj.xml"
    [ -f "$prj_file" ] || die "$prj_file is not a file"
    [ -r "$prj_file" ] || die "$prj_file is not readable"
done

trap "cleanup ; exit" INT TERM EXIT
if [ $SSH_MODE -eq 1 ] ; then
    TMP_DIR=$(mktemp -d /tmp/ec_import_projects.XXXXX)
else
    TMP_DIR=$(mktemp -d $nix_tmp_path/${SCM_USER}_ec_import_projects.XXXXX) ||
        die "Failed to create shared TMP_DIR"
    chmod a+rx $TMP_DIR
fi

if [ "$VERBOSE" == "1" ]; then echo "tmp dir = \`$TMP_DIR'"; fi

if [ $SSH_MODE -eq 1 ] ; then
    create_remote_temp_dir "$HOST" "$SCRIPT_MODE" "$SSH_OPTS"
    REMOTE_TMP_DIR="$_REMOTE_TMP_DIR"
else
    REMOTE_TMP_DIR=${TMP_DIR/$nix_tmp_path/$server_tmp_path}
fi

for prj in $PROJECTS ; do

    if [ ! -z "$PRJ_PREFIX" -o ! -z "$PRJ_SUFFIX" ] ; then
        for p in $REF_PROJECTS; do
            sre+="-e s|\<$p\>|$PRJ_PREFIX$p$PRJ_SUFFIX|gI "
        done
    fi

    get_repo_dir_for_prj "$prj" "$FLAT_MODE" "$CONFIG_FILE" \
        "$SCRIPT_PATH" "$MANIFEST"
    prj_file="$DIR/$_REPO_DIR/$prj.xml"

    if [ ! -z "$sre" ] ; then
        sed $sre "$prj_file" > "$TMP_DIR/$prj.xml"
    else
        cp "$prj_file" "$TMP_DIR/$prj.xml"
    fi

done

if [ $SSH_MODE -eq 1 ] ; then
    set +o errexit
    cd $TMP_DIR && tar cpzf $TMP_DIR/projects.tar.gz *.xml && cd - > /dev/null
    [ $? -eq 0 ] || die "error: tar failed"
    set -o errexit

    eval scp $SSH_OPTS $TMP_DIR/projects.tar.gz $HOST:$REMOTE_TMP_DIR ||
        die "error: scp failed"

    eval ssh $SSH_OPTS $HOST chmod a+rx $REMOTE_TMP_DIR

    eval ssh $SSH_OPTS $HOST tar -x -p -z -f $REMOTE_TMP_DIR/projects.tar.gz \
     -C $REMOTE_TMP_DIR ||
        die "error: untar failed"
fi

if [ $SCRIPT_MODE -eq 0 ] ; then

    UPROJECTS=$( echo $PROJECTS |
                sed -e "s:\([^ ]*\):$PRJ_PREFIX\1$PRJ_SUFFIX:g")

    user_prompt=$(cat <<END_OF_PROMPT

Are you sure you want to deploy the following
  server: $HOST
  projects: $PROJECTS (from $DIR)
  deploy as: $UPROJECTS

  Option --use-suffix can be used to control sandbox naming convention.

END_OF_PROMPT
)

    user_continue_abort "$user_prompt"
fi

if [ $ATOMIC -eq 1 ] ; then
    [ $VERBOSE -ge 1 ] && verb_atomic="--verbose"
    [ $EC_FORCE -eq 1 ] && force_atomic="--ec-force"

    atomic_cmd_line="$SCRIPT_PATH/ec_import_atomic.pl --disable-schedules $force_atomic "
    atomic_cmd_line+="--server=$HOST $verb_atomic "
    [ ! -z "$PRJ_PREFIX" ] && atomic_cmd_line+="--prefix=$PRJ_PREFIX "
    [ ! -z "$PRJ_SUFFIX" ] && atomic_cmd_line+="--suffix=$PRJ_SUFFIX "
    atomic_cmd_line+="$verb_atomic $TMP_DIR $REMOTE_TMP_DIR"

    [ $VERBOSE -ge 1 ] &&
        printf "Command line for atomic import:\n$atomic_cmd_line\n\n"

    $atomic_cmd_line || die "error: atomic ectool import failed"
else
    for prj in $PROJECTS ; do
        [ $VERBOSE -ge 1 ] && echo  "Importing $PRJ_PREFIX$prj$PRJ_SUFFIX..."
        prj_file="$REMOTE_TMP_DIR/$prj.xml"

        ectool --server "$HOST" import "$prj_file" --disableSchedules 1 \
            --path /projects/"$PRJ_PREFIX$prj$PRJ_SUFFIX" --force $EC_FORCE ||
        die "error: ectool import failed for $PRJ_PREFIX$prj$PRJ_SUFFIX"
    done
fi

#TODO (LOW_PRIORITY): acls should be set atomically along with import
#      of projects if ATOMIC=1. In practice this is a small window
#      that would only affect jobs running during the import. We can't
#      guarantee these jobs won't be failed due to import outside of
#      this. Also, these will almost always be imported with acls set
#      properly to being with.

for prj in $PROJECTS ; do
     if [[ $prj == *_[Mm][Aa][Ii][Nn] ]] ||
        [[ $prj == *_[Cc][Oo][Mm][Mm][Oo][Nn] ]] ||
        [[ $prj == [Bb][Aa][Ii][Tt]_[Ss][Cc][Mm]* ]] ; then
        [ "$VERBOSE" -ge 1 ] && echo "    Checking/updating system ACLs..."

        #If acl already exists it is not modified
        #Modify on Resources allows access to createResource and deleteResource
        create_default_acl "+r+w" "$HOST" "$PRJ_PREFIX$prj$PRJ_SUFFIX" \
                           "system" "resources"
        create_default_acl "+r+w+x" "$HOST" "$PRJ_PREFIX$prj$PRJ_SUFFIX" \
                           "system" "server"

        if [[ $prj == [Aa][Nn][Dd][Rr][Oo][Ii][Dd]_[Mm][Aa][Ii][Nn] ]] ||
            [[ $prj == [Aa][Nn][Dd][Rr][Oo][Ii][Dd]_[Cc][Oo][Mm][Mm][Oo][Nn] ]]
        then
            [ "$VERBOSE" -ge 1 ] && echo "    Checking/updating project ACLs..."
            #If acl already exists it is not modified
            create_default_acl "+r+w+x" "$HOST" "$PRJ_PREFIX$prj$PRJ_SUFFIX"\
                                "project" "Android_Autogenerated"
        fi

        [ $VERBOSE -ge 1 ] && echo "done."
    fi
done

if [ $VERBOSE -ge 1 ] ; then
    echo ; echo "Done importing projects."
fi

trap - INT TERM EXIT
cleanup
exit 0
