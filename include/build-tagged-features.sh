#!/bin/bash

P2_PATH=$1

find -name "feature.xml" -exec cp {} {}.orig \;
find -name "feature.xml" -exec sed -r -i -e "s:(label=\"[^\"]*)\":\\1 \\[${P2_PATH}]\":g" {} \;
mvn verify
find -name "feature.xml" -exec rm {} \;
find -name "feature.xml.orig" -exec sh -c 'mv $0 "${0%.orig}"' {} \;
