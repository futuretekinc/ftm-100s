/*
 * Squashfs - a compressed read only filesystem for Linux
 *
 * Copyright (c) 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009
 * Phillip Lougher <phillip@lougher.demon.co.uk>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2,
 * or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * lzma_wrapper.c
 */

#include <asm/unaligned.h>
#include <linux/buffer_head.h>
#include <linux/mutex.h>
#include <linux/vmalloc.h>
#include <linux/decompress/unlzma.h>
#include <linux/slab.h>

#include "squashfs_fs.h"
#include "squashfs_fs_sb.h"
#include "squashfs_fs_i.h"
#include "squashfs.h"
#include "decompressor.h"

struct squashfs_lzma {
	void	*input;
	void	*output;
};

/* decompress_unlzma.c is currently non re-entrant... */
DEFINE_MUTEX(lzma_mutex);

/* decompress_unlzma.c doesn't provide any context in its callbacks... */
static int lzma_error;

static void error(char *m)
{
	ERROR("unlzma error: %s\n", m);
	lzma_error = 1;
}

	
static void *lzma_init(struct squashfs_sb_info *msblk, void *buff, int len)
{
	struct squashfs_lzma *stream = kzalloc(sizeof(*stream), GFP_KERNEL);
	if (stream == NULL)
		goto failed;
	stream->input = vmalloc(msblk->block_size);
	if (stream->input == NULL)
		goto failed;
	stream->output = vmalloc(msblk->block_size);
	if (stream->output == NULL)
		goto failed2;

	return stream;

failed2:
	vfree(stream->input);
failed:
	ERROR("failed to allocate lzma workspace\n");
	kfree(stream);
	return NULL;
}


static void lzma_free(void *strm)
{
	struct squashfs_lzma *stream = strm;

	if (stream) {
		vfree(stream->input);
		vfree(stream->output);
	}
	kfree(stream);
}


static int lzma_uncompress(struct squashfs_sb_info *msblk, void **buffer,
	struct buffer_head **bh, int b, int offset, int length, int srclength,
	int pages)
{
	struct squashfs_lzma *stream = msblk->stream;
	void *buff = stream->input;
	int avail, i, bytes = length, res;

	mutex_lock(&lzma_mutex);

	for (i = 0; i < b; i++) {
		wait_on_buffer(bh[i]);
		if (!buffer_uptodate(bh[i]))
			goto block_release;

		avail = min(bytes, msblk->devblksize - offset);
		memcpy(buff, bh[i]->b_data + offset, avail);
		buff += avail;
		bytes -= avail;
		offset = 0;
		put_bh(bh[i]);
	}

	lzma_error = 0;
	res = unlzma(stream->input, length, NULL, NULL, stream->output, NULL,
							error);
	if (res || lzma_error)
		goto failed;

	/* uncompressed size is stored in the LZMA header (5 byte offset) */
	res = bytes = get_unaligned_le32(stream->input + 5);
	for (i = 0, buff = stream->output; bytes && i < pages; i++) {
		avail = min_t(int, bytes, PAGE_CACHE_SIZE);
		memcpy(buffer[i], buff, avail);
		buff += avail;
		bytes -= avail;
	}
	if (bytes)
		goto failed;

	mutex_unlock(&lzma_mutex);
	return res;

block_release:
	for (; i < b; i++)
		put_bh(bh[i]);

failed:
	mutex_unlock(&lzma_mutex);

	ERROR("lzma decompression failed, data probably corrupt\n");
	return -EIO;
}

const struct squashfs_decompressor squashfs_lzma_comp_ops = {
	.init = lzma_init,
	.free = lzma_free,
	.decompress = lzma_uncompress,
	.id = LZMA_COMPRESSION,
	.name = "lzma",
	.supported = 1
};

