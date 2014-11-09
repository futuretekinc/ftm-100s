
#define	DO1(buf) crc = crc_table[((int)crc ^ (*buf++)) & 0xff] ^ (crc >> 8);
#define DO2(buf)  DO1(buf); DO1(buf);
#define DO4(buf)  DO2(buf); DO2(buf);
#define DO8(buf)  DO4(buf); DO4(buf);

/* ========================================================================= */
uint32_t crc32 (uint32_t crc, const Bytef *buf, uInt len)
{
#ifdef DYNAMIC_CRC_TABLE
    if (crc_table_empty)
		make_crc_table();
#endif
	crc = crc ^ 0xffffffffL;
	while (len >= 8)
	{   
		DO8(buf);
		len -= 8;
	}   
	if (len) 
	{
		do 
		{
			DO1(buf);
		} while (--len);
	}	

	return crc ^ 0xffffffffL;
}


