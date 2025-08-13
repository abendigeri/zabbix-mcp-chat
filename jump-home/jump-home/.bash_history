ls
mkdir /root/mcpdemo
cd /root/mcpdemo
pythn
python -v
apt-get update && apt-get install -y --no-install-recommends     curl ca-certificates gnupg software-properties-common     gcc build-essential  && rm -rf /var/lib/apt/lists/*
add-apt-repository ppa:deadsnakes/ppa -y  && apt-get update && apt-get install -y --no-install-recommends     python3.13 python3.13-venv python3.13-dev  && ln -sf /usr/bin/python3.13 /usr/bin/python3  && ln -sf /usr/bin/python3.13 /usr/bin/python  && rm -rf /var/lib/apt/lists/*
apt-get update
pipx install uv
apt-get install pipx
pipx install uv
uv venv --python 3.13
uv pip install mcpo
ls
uv
uv venv --python 3.13 --clear
uv pip install mcpo
uvx mcpo --port 9000 --api-key "topsecret" --server-type "streamable-http" -- http://zabbix-mcp:8000/mcp
exit
cd /root/mcpdemo
ls
python test_script.py 
uv run python test_script.py 
vi test_script.py 
apt install vim
vi test_script.py 
uv run python test_script.py 
vi test_script.py 
uv run python test_script.py 
exit
