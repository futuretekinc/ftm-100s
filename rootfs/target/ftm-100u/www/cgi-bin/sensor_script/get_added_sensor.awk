BEGIN {
    res = "empty";
}
{
    if ($1 > 0)
    {
        res = "exist";
    }
}
END {
    print res;
}
