# run this script from will prepare data and train model and then generate a submission file.
source('prepare_data.r')
source('fun.r')
library(xgboost)

train_dir="/Downloads/season_1/training_data/"
test_dir="/Downloads/season_1/test_set_1/"
train.dat=prepare_train_data(train_dir)
test.dat=prepare_test_data(test_dir)
save(train.dat,test.dat,file='didi.dat')# for future use

# train xgb model
# without poi variables for now
vars=c("gap_past_1"      ,        "gap_past_2"     ,         "gap_past_3"           ,  
         "id"        ,                  
        "placed_past_1"   ,        "placed_past_2"      ,       "placed_past_3"   ,               
         "timeslice"  ,                  
         "total_past_1"           ,"total_past_2"     ,       "total_past_3"     ,       
         "traffic_l1_past1"   ,     "traffic_l2_past1"  ,     "traffic_l3_past1"  ,      "traffic_l4_past1"  , 
         "traffic_l1_past2" ,       "traffic_l2_past2"    ,    "traffic_l3_past2"   ,    "traffic_l4_past2"   ,  
         "traffic_l1_past3"   ,     "traffic_l2_past3"  ,      "traffic_l3_past3"     ,   "traffic_l4_past3"    ,   
         "weather_condition_past1", "weather_condition_past2", "weather_condition_past3",
         "weather_pm25_past1"  ,    "weather_pm25_past2"   ,   "weather_pm25_past3"   , 
         "weather_temp_past1"  ,    "weather_temp_past2" ,     "weather_temp_past3"   , 
         "weekday" )
         
train=sample.timeslot(T)# T means using the exact timeslots for leaderboard; F meas using random timeslots
train.dt=train.gap[day %in% train[[1]] ,c(vars,'gap'),with=F]
test.dt=train.gap[day %in% train[[2]] & timeslice %in% train[[3]],c(vars,'gap'),with=F]

dtrain=xgb.DMatrix(data=data.matrix(train.dt[,vars,with=F]),label=train.dt$gap,missing=NA)
dval=xgb.DMatrix(data=data.matrix(test.dt[,vars,with=F]),label=test.dt$gap,missing=NA)
dtest=xgb.DMatrix(data=data.matrix(test.gap[,vars,with=F]),
                  missing=NA)
watchlist = list(train=dtrain, test=dval)
params = list(booster='gbtree',
              #objective='reg:linear',
              objective=mapeObj,
              eval_metric=evalMAPE,           
              #lambda=1,
              subsample=0.7,
              colsample_bytree=0.6,
              #min_child_weight=minchildweight,
              max_depth=8,
              eta=0.05,
              watchlist =watchlist
)

set.seed(1)
fit = xgb.train(data=dtrain, nround=500, watchlist=watchlist,params=params)
