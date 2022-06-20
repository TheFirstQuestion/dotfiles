if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	WHO="$(hostname)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	WHO='sMac'
fi

WHEN="$(date '+%A, %B %d, %Y, %I:%M:%S %p %Z')"
keybase chat send sophie_opferman --channel logs "$WHO -- $WHEN -- $1"
