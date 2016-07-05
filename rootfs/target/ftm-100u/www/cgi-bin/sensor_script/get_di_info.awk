BEGIN {
    count=0;
    idx=0;
}
{
    if ($1 ~ /^count/)
    {
        count = $2;
    }

    if ($1 ~ /^mac/)
    {
        mac = $2;
    }
    
    idx = idx % count;
#    print idx, count;
    if ($1 ~ /^iso.3.6.1.4.1.42251.1.3.1280.2.1.1/)
    {
        ids[idx] = $4;
    }
    
    if ($1 ~ /^iso.3.6.1.4.1.42251.1.3.1280.2.1.2/)
    {
        types[idx] = $4 $5;
    }
    
    if ($1 ~ /^iso.3.6.1.4.1.42251.1.3.1280.2.1.3/)
    {
        names[idx] = $4;
    }

    if ($1 ~ /^iso.3.6.1.4.1.42251.1.3.1280.2.1.4/)
    {
        serials[idx] = $4;
    }

    if ($1 ~ /^iso.3.6.1.4.1.42251.1.3.1280.2.1.5/)
    {
        states[idx] = $4;
    }

    if ($1 ~ /^iso.3.6.1.4.1.42251.1.3.1280.2.1.6/)
    {
        values[idx] = $4;
    }

    if ($1 ~ /^iso.3.6.1.4.1.42251.1.3.1280.2.1.7/)
    {
        lastvalues[idx] = $4;
    }

    if ($1 ~ /^iso.3.6.1.4.1.42251.1.3.1280.2.1.8/)
    {
        lasttimes[idx] = $4;
    }
    
    if ($1 ~ /^iso.3.6.1.4.1.42251.1.3.1280.2.1.9/)
    {
        intvalue[idx] = $4;
    }

    idx += 1;
}
END {
    for (i=0; i<count; i++)
    {
        print mac, ids[i], types[i], names[i], serials[i], states[i], values[i], lastvalues[i], lasttimes[i], intvalue[i];
    }
}
