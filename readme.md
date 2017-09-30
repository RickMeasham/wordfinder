# DOCKER QUICK START #

Use Docker to execute the code in this repository

    $ docker build -t wordfinder .
    ...
    $ docker run -d -p 8080:80 wordfinder
    ...
    
# TESTING #

    $ curl -I http://localhost:8080/ping
    HTTP/1.1 200 OK

    $ curl http://localhost:8080/wordfinder/god
    ["do","dog","go","god","od"]

# THE CODE #

There are two important files in this repository: 

script/wordfinder is the controller. It takes the input from the HTTP request and sends the output back to the user.

lib/Wordfinder/Model/FindWords.pm is the model that does the work of finding matching words. The solution approach is documented in this file.


The third file of note is in usr/share/dict/sowpods. This is an alternate words file. Details on how to use this are in FindWords.pm.
