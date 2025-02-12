module c3tools::lsp::log;
import std::io;

macro error($format, ...)
{
    io::eprintfn(
        "ERROR - (%s:%d) " +++ $format,
        $$FILE,
        $$LINE,
        $vasplat,
    );
}

macro debug($format, ...)
{
    io::eprintfn(
        "DEBUG - (%s:%d) " +++ $format,
        $$FILE,
        $$LINE,
        $vasplat,
    );
}
