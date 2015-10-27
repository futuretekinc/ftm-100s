#!/bin/sh

mmd -p /dev/ttyS1 -c at+cpin? | awk 'BEGIN{ retval="false" }{\
		if ($1 ~ /\+CPIN:/)\
		{\
				if ($2 ~ /READY/)\
				{\
						retval="ready"\
				}\
		} else if ($1 ~ /\+CME/)\
		{\
				if ($3 ~ /10/)\
				{\
						retval="10"\
				}\
		}\
}END{ print retval }'
