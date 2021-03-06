# Main model, spatiotemporal soap film smooth
# smooth Italy, Sardinia and Sicily...

# first load some libraries
library(maps)
library(mapdata)
library(soap)
library(dillhandy)

# extra scripts - to re-organise the data
source("fixit.R")

# run fixdata anyway to get the boundaries
full<-read.csv(file="database_complete.csv")
fixdat<-fix_it_data(full)

# if we want to use Gamma distribution then add a small number
# to the data, don't need to if Tweedie errors
eps<-0 # if Tweedie
#eps<-1e-8 # if Gamma 

# Italy boundary
it<-list(x=fixdat$italy$map$km.e,y=fixdat$italy$map$km.n)
# Sardinia boundary
sa<-list(x=fixdat$sardinia$map$km.e,y=fixdat$sardinia$map$km.n)
# Sicily boundary
sc<-list(x=fixdat$sicily$map$km.e,y=fixdat$sicily$map$km.n)

########################
# Italy

# form the data set
it.dat<-list(x=fixdat$italy$dat$km.e,
          y=fixdat$italy$dat$km.n,
          year=fixdat$italy$dat$year,
          share_100=fixdat$italy$dat$share_100+eps)

# basis size
it.bsize<-c(20,6)
# setup the soap knots
soap.knots.it<-make_soap_grid(it,c(14,14))
soap.knots.it<-pe(soap.knots.it,-c(25)) #14 x14
# set the Tweedie parameter
tweediepar<-1.2

# run the model
it.soap<- gam(share_100~
   te(x,y,year,bs=c("sf","cr"),k=it.bsize,d=c(2,1),xt=list(list(bnd=list(it)),NULL))+
   te(x,y,year,bs=c("sw","cr"),k=it.bsize,d=c(2,1),xt=list(list(bnd=list(it)),NULL))
         ,knots=soap.knots.it,data=it.dat,family=Tweedie(link=power(0),p=tweediepar),method="REML")
# comment the line above and uncomment the one below for Gamma errors
#            ,knots=soap.knots.it,data=it.dat,family=Gamma(link="log"),method="REML")
##########################

gc() # take out the trash - save some memory

########################
# Sardinia 

# form the data set
sa.dat<-list(x=fixdat$sardinia$dat$km.e,
          y=fixdat$sardinia$dat$km.n,
          year=fixdat$sardinia$dat$year,
          share_100=fixdat$sardinia$dat$share_100+eps)

soap.knots.sa<-make_soap_grid(sa,c(5,6))

sa.ksize<-c(8,6)

sa.soap<- gam(share_100~
   te(x,y,year,bs=c("sf","cr"),k=sa.ksize,d=c(2,1),xt=list(list(bnd=list(sa)),NULL))+
   te(x,y,year,bs=c("sw","cr"),k=sa.ksize,d=c(2,1),xt=list(list(bnd=list(sa)),NULL))
        ,knots=soap.knots.sa,data=sa.dat,family=Tweedie(link=power(0),p=tweediepar),method="REML")
# comment the line above and uncomment the one below for Gamma errors
#        ,knots=soap.knots.sa,data=sa.dat,family=Gamma(link="log"),method="REML")
##########################
gc()

########################
# Sicily 

# form the data set
sc.dat<-list(x=fixdat$sicily$dat$km.e,
          y=fixdat$sicily$dat$km.n,
          year=fixdat$sicily$dat$year,
          share_100=fixdat$sicily$dat$share_100+eps)

# setup the soap knots
soap.knots.sc<-make_soap_grid(sc,c(6,6))

sc.bsize<-c(10,6)
sc.soap<- gam(share_100~
   te(x,y,year,bs=c("sf","cr"),k=sc.bsize,d=c(2,1),xt=list(list(bnd=list(sc)),NULL))+
   te(x,y,year,bs=c("sw","cr"),k=sc.bsize,d=c(2,1),xt=list(list(bnd=list(sc)),NULL))
         ,knots=soap.knots.sc,data=sc.dat,family=Tweedie(link=power(0),p=tweediepar),method="REML")
# comment the line above and uncomment the one below for Gamma errors
#          ,knots=soap.knots.sc,data=sc.dat,family=Gamma(link="log"),method="REML")
##########################
gc()


########################
# now make the image plot

# set the plotting resolution in time and space
grid.res.x<-100
grid.res.y<-60
years<-as.numeric(levels(as.factor(it.dat$year)))

# setup the prediction grid
xmin<-min(c(it$x,sa$x,sc$x))
ymin<-min(c(it$y,sa$y,sc$y))
xmax<-max(c(it$x,sa$x,sc$x))
ymax<-max(c(it$y,sa$y,sc$y))
xm <- seq(xmin,xmax,length=grid.res.x);yn<-seq(ymin,ymax,length=grid.res.y)
xx <- rep(xm,grid.res.y);yy<-rep(yn,rep(grid.res.x,grid.res.y))
im.mat<-matrix(NA,length(years),grid.res.x*grid.res.y)

# which grid points relate to which places?
it.onoff<-inSide(it,xx,yy)
sa.onoff<-inSide(sa,xx,yy)
sc.onoff<-inSide(sc,xx,yy)

# do the prediction and insert into the grid
for (i in 1:length(years)){
   pred.grid<-list(x=xx,y=yy,year=rep(years[i],length(xx)))
   # italy
   im.mat[i,it.onoff]<-predict(it.soap,pe(pred.grid,it.onoff),type="response")
   # sardinia
   im.mat[i,sa.onoff]<-predict(sa.soap,pe(pred.grid,sa.onoff),type="response")
   # sicily
   im.mat[i,sc.onoff]<-predict(sc.soap,pe(pred.grid,sc.onoff),type="response")
}

# limits for the plot   
xlim<-c(xm[1]-25,xm[length(xm)]+25)
ylim<-c(yn[1]-25,yn[length(yn)]+25)
zlim<-c(0,12)

######################
# SAVE
######################
save.image(paste("fullmod-",it.soap$family[[1]],".RData",sep=""))


######################
# PLOTTING
######################

#pdf(paste("maps-",it.soap$family[[1]],".pdf",sep=""),width=9)
postscript(paste("maps-",it.soap$family[[1]],".ps",sep=""),width=9)
par(mfrow=c(2,3),mar=c(4.5,4.5,2,2))

for (i in 1:length(years)){
   # plot the image
   image(z=matrix(im.mat[i,],grid.res.x,grid.res.y),x=xm,y=yn,
         col=heat.colors(100),xlab="km (e)",ylab="km (n)",
         main=years[i],asp=1,cex.main=1.4,
         cex.lab=1.4,cex.axis=1.3,zlim=zlim,xlim=xlim,ylim=ylim)

   # then the contour ontop
   contour(xm,yn,matrix(im.mat[i,],grid.res.x,grid.res.y),
            levels=seq(zlim[1],zlim[2],by=1),col="blue",add=TRUE)

   # then the country borders
   lines(it,lwd=2)
   lines(sa,lwd=2)
   lines(sc,lwd=2)

}
dev.off()

