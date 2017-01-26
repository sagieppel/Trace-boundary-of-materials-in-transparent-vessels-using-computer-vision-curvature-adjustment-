# Trace-boundary-of-materials-in-transparent-vessels-using-computer-vision-curvature-adjustment-
Given an image of material inside a transparent vessel and the boundary of the vessel in the image, recognize and mark the boundary of materials inside a transparent container in images. This method similar to the one in: 
http://www.mathworks.com/matlabcentral/fileexchange/49076-find-the-boundaries-of-materials-in-transparent-vessels-using-computer-vision 
But improve it by using the vessel curvature to adjust for reflections from the vessel surface 
Could be used to trace the boundary of both solids, liquid powders and granular materials. 
Input: Image of some material in a transparent vessel and the boundaries of the vessel in the image (as binary contour image). 
Output: Recognized and mark the boundary of the material inside the vessel. 
Documentation and instruction are included in the Readme file in the code.

The code was made specifically for glass vessels in chemistry laboratory, but could be used for other cases of solids and fluids in transparent containers.

The source code is based on the method described in the paper: “Tracing the boundaries of materials in transparent vessels using computer vision” Freely available at Arxiv: 
http://arxiv.org/ftp/arxiv/papers/1501/1501.04691.pdf
