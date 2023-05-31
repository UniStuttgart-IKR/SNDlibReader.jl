export readgraph, readdemands

function getcoords(gr::AbstractGraph, nd::Int)
    return [get_prop(gr, nd, :xcoord), get_prop(gr, nd, :ycoord)]
end

function readgraph(filepath::String)
    grdoc = EzXML.readxml(filepath)
    abroot = grdoc.root
    ns = EzXML.namespace(abroot)


    nodesxml = EzXML.findall("//x:nodes/x:node", abroot, ["x" => ns])
    linksxml = EzXML.findall("//x:links/x:link", abroot, ["x" => ns])
    demandsxml = EzXML.findall("//x:demands/x:demand", abroot, ["x" => ns])

    gr = MetaDiGraph()
    for (i,nodexml) in enumerate(nodesxml)
        @assert add_vertex!(gr)
        set_prop!(gr, i, :name, nodexml["id"])
        nodex = EzXML.findfirst("ns:coordinates/ns:x", nodesxml[i], ["ns" => ns])
        set_prop!(gr, i, :xcoord, parse(Float64, EzXML.nodecontent(nodex)))
        nodey = EzXML.findfirst("ns:coordinates/ns:y", nodesxml[i], ["ns" => ns])
        set_prop!(gr, i, :ycoord, parse(Float64, EzXML.nodecontent(nodey)))
    end
    set_indexing_prop!(gr, :name)

    for linkxml in linksxml
        linksource = EzXML.findfirst("ns:source", linkxml, ["ns" => ns]) |> EzXML.nodecontent
        linktarget = EzXML.findfirst("ns:target", linkxml, ["ns" => ns]) |> EzXML.nodecontent
        @assert add_edge!(gr, gr[linksource, :name], gr[linktarget, :name])
        @assert add_edge!(gr, gr[linktarget, :name], gr[linksource, :name])
        distance = haversine(getcoords(gr, gr[linksource, :name]), getcoords(gr, gr[linktarget, :name]), EARTH_RADIUS)
        set_prop!(gr, gr[linksource, :name], gr[linktarget, :name], :length, distance)
        set_prop!(gr, gr[linktarget, :name], gr[linksource, :name], :length, distance)
    end

    weightfield!(gr, :length)

    for demandxml in demandsxml
        demandsource = EzXML.findfirst("ns:source", demandxml, ["ns" => ns]) |> EzXML.nodecontent
        demandtarget = EzXML.findfirst("ns:target", demandxml, ["ns" => ns]) |> EzXML.nodecontent
        demandvalue = parse(Float64, EzXML.nodecontent(EzXML.findfirst("ns:demandValue", demandxml, ["ns" => ns])))
        set_prop!(gr, gr[demandsource, :name], gr[demandtarget, :name], :demand, demandvalue)
    end

    for v in vertices(gr)
        if get_prop(gr, v, :name ) == "ATLAM5"
            rem_vertex!(gr, v)
            break
        end
    end

    return gr
end

function readdemands(filepath::String; scale=1)
    grdoc = EzXML.readxml(filepath)
    abroot = grdoc.root
    ns = EzXML.namespace(abroot)
    demandsxml = EzXML.findall("//x:demands/x:demand", abroot, ["x" => ns])
    ds = Dict{Tuple{String, String}, Float64}()
    for demandxml in demandsxml
        demandsource = EzXML.findfirst("ns:source", demandxml, ["ns" => ns]) |> EzXML.nodecontent
        demandtarget = EzXML.findfirst("ns:target", demandxml, ["ns" => ns]) |> EzXML.nodecontent
        demandvalue = parse(Float64, EzXML.nodecontent(EzXML.findfirst("ns:demandValue", demandxml, ["ns" => ns])))
        ds[(demandsource, demandtarget)] = demandvalue * scale
    end
    filter!(d -> !("ATLAM5" in d.first), ds)
    return ds
end

