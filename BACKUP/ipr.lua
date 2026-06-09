for i=0,net.route.getlen()-1,1
do
  route=net.route.get(i)
  if (route['dest']) then
    line=''
    for key, value in pairs(net.route.get(i))
    do
      line=line..key..'='..value..' '
    end
    print(line)
  end
end