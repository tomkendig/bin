#!/usr/csh -f
date
ectool getUsers -timeout 360 | wc
date
ectool getUser tkendig | wc
date
ectool modifyUser tkendig | wc
date
