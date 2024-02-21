# Example to see modifications in upgrade native packages

When we are using the pipe to pass data from one command to another, a buffer is used to optimize the system, but we want the output to be continuous. That's why we start pacman using unbuffer, while the \--unbuffered parameter in jq is not really necessary, but it improves performance.

We could use only bash built-ins to filter the output of pactrans and generate the output in .json format. We would use the same regular expressions, but with jq it is easier for us to know that the output is indeed a valid .json.

# upgrade
    unbuffer pactrans --sysupgrade --yolo --print-only | jq --unbuffered -Rn -f jq/pactrans.jq

# install
    unbuffer pactrans --install --yolo --print-only gimp | jq --unbuffered -Rn -f jq/pactrans.jq

# remove
    unbuffer pactrans --remove --yolo --print-only --cascade --recursive --unneeded gimp | jq --unbuffered -Rn -f jq/pactrans.jq
