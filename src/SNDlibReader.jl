module SNDlibReader

using Graphs, MetaGraphs
import EzXML
import Distances: haversine

# earth radius in km
const EARTH_RADIUS = 6371

include("SNDlibXMLDeserializer.jl")

end
