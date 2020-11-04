while true; do
	#curl http://isv.app -s -o /dev/null -I -w "%{http_code}";
	curl -w "\n" http://isv.app/version
	curl -w "\n" http://isv.app/api/version
	curl -w "\n" http://cannary.isv.app/version --header "Host: cannary.isv.app"
	curl -w "\n" http://cannary.isv.app/api/version
	sleep 1;
done
