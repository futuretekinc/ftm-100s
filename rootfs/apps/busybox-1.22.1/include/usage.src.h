/* vi: set sw=8 ts=8: */
/*
 * This file suffers from chronically incorrect tabification
 * of messages. Before editing this file:
 * 1. Switch you editor to 8-space tab mode.
 * 2. Do not use \t in messages, use real tab character.
 * 3. Start each source line with message as follows:
 *    |<7 spaces>"text with tabs"....
 * or
 *    |<5 spaces>"\ntext with tabs"....
 */
#ifndef BB_USAGE_H
#define BB_USAGE_H 1

#define NOUSAGE_STR "\b"

INSERT

#define lock_trivial_usage \
		"[-suw] <filename>" \

#define lock_full_usage "\n\n" \
		"Small utility for using locks in scripts \n" \
 		"\n	 -s      Use shared locking" \
  		"\n	 -u      Unlock"  \
	 	"\n	 -w      Wait for the lock to become free, don't acquire lock" 

#define busybox_notes_usage \
       "Hello world!\n"

#endif
