# aba-gene-explorer
A sample Xcode project to display gene expression data from the Allen Brain Atlas

The Allen Mouse and Human Brain Atlases, freely available to the public, have served as valuable resources for the neuroscience community for nearly a decade. The Allen Brain Institute makes these resources even more accessible with the Allen Brain Atlas (ABA) API (http://www.brain-map.org/api/index.html). This Xcode project provides an example of an app that can query the Allen Mouse Brain Atlas for genome-wide in situ hybridization (ISH) image data for rapid display. For this atlas, the expression patterns of approximately 20,000 genes were mapped throughout the adult mouse brain. 

In this sample project, the user may select a gene for which there is image data available and navigate through sections of a brain to observe expression in different brain regions. For this sample, a subset of 50 genes are parsed from a JSON response provided by the Allen Brain Institute in order to populate the gene list. Of note, query responses from the Allen Brain Institute can also be received as XML and CSV for parsing. For a given gene, there is typically a set of sagittal image sections available and occasionally a set of coronal sections. If sections from both planes are available for a given gene, the user can toggle between these planes.

For more details on querying data available from the Mouse Brain Atlas:
http://help.brain-map.org/display/mousebrain/API

For more details on downloading images from the Allen Brain Institute:
http://help.brain-map.org/display/api/Downloading+an+Image

