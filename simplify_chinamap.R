library(dplyr)
library(rmapshaper)
library(sf)
library(stringr)

#' # 使用新版的地图数据

# chinamap 
# Thanks to @一棵树 and biobabble for providing county-lvl and recent chinamap data [source: 高德地图]
files <- list.files(path = "data-raw/中国_行政边界/",pattern = "shp$",all.files = TRUE,full.names = T,recursive = T)

shapes <- lapply(files, function(file){
  data <- read_sf(file)
  provinceName <- gsub(pattern = ".*//",replacement = "",file)
  provinceName <- gsub(pattern = "_.*",replacement = "",provinceName)
  data$ProvinceName <- provinceName
  return(data)
})

chinamap <- do.call("rbind",shapes)

chinamap$geometry <- ms_simplify(chinamap$geometry)
# write_sf(chinamap,dsn="chinamap_lite.shp")

# chinamap <- sf::read_sf("inst/chinamap_lite/chinamap_lite.shp")

province_suffix <-  "省|市|自治区|维吾尔自治区|回族自治区|壮族自治区|特别行政区"
province <- subset(chinamap, Layer=="省") %>%
  mutate(name = str_remove_all(Name, pattern = province_suffix))

# 保存 province
saveRDS(province,file = "china_province.RDS")


# 同样处理市一级水平地图数据
city_suffix <- "市|区|新区|城区|回族|藏族|苗族|群岛|布依族|侗族|黎族|地区|林区|蒙古族|朝鲜族|土家族|壮族|傈僳族|哈尼族|彝族|傣族|景颇族|哈萨克|白族|蒙古"
city <- subset(chinamap, Layer=="市" | ( Layer=="区县" & str_detect(ProvinceName,"市") )) %>%
  mutate(name=str_remove_all(Name,pattern = city_suffix),
         provinceShortName=str_remove_all(ProvinceName, pattern = province_suffix))
saveRDS(city,file = "china_city.RDS")
