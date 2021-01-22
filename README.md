# verify-kit

##
1. Copy pms_session.env to $HOME directory
2. Start the proxy: ./k8s_config_provider.sh staging
3. Run the script: ./pms_migrate.sh -a "falk" -d "falk1.com" -s ~/pms_session.env