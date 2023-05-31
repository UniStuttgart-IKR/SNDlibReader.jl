using SNDlibReader
using Test
using Pkg.Artifacts

using Graphs, MetaGraphs

import EzXML
import Distances: haversine

# earth radius in km
const EARTH_RADIUS = 6371

function getcoords(gr::AbstractGraph, nd::Int)
    return [get_prop(gr, nd, :x), get_prop(gr, nd, :y)]
end

abilene = artifact"sndlib-networks" * "/sndlib-networks-xml/abilene.xml"
gr = readgraph(abilene)

