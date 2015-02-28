//
//  ImgProcWrapper.m
//  ideawork
//
//  Created by Ray Cai on 2015/2/23.
//  Copyright (c) 2015 Ray Cai. All rights reserved.
//

#import "ImgProcWrapper.h"

#import <UIKit/UIKit.h>

#include <opencv2/opencv.hpp>


@implementation ImgProcWrapper

cv::Scalar transparentColor =cv::Scalar(255,255,255,255);

// public functions
+(UIImage *) capture:(UIImage *)image scale:(float)scale displacementX:(int)displacementX displacementY:(int)displacementY{
    cv::Mat inputMat = cvMatFromUIImage(image);
    
    int originalWidth = inputMat.cols;
    int originalHeight = inputMat.rows;
    
    
    // consider that movement direction of viewpoint is converse than touch movement
    int outputCenterXOnOriginalImage = int(originalWidth/2-displacementX);
    int outputCenterYOnOriginalImage = int(originalHeight/2-displacementY);
    
    int cropWidth = int(originalWidth/scale);
    int cropHeight = int(originalHeight/scale);
    
    int leftCropPointOnOriginalImage = int(outputCenterXOnOriginalImage-cropWidth/2);
    int rightCropPointOnOriginalImage = leftCropPointOnOriginalImage+cropWidth;
    
    int topCropPointOnOriginalImage = int(outputCenterYOnOriginalImage-cropHeight/2);
    int bottomCropPointOnOriginalImage = topCropPointOnOriginalImage+cropHeight;
    
    // check if entire image is moved out of view
    if(rightCropPointOnOriginalImage<=0 || leftCropPointOnOriginalImage >=originalWidth || topCropPointOnOriginalImage>=originalHeight || bottomCropPointOnOriginalImage<=0){
        //entire image is moved out of view
        cv::Mat outputMat = cv::Mat(originalHeight,originalWidth,CV_8UC4,transparentColor);
        
        UIImage* outputImage = UIImageFromCVMat(outputMat);
        
        return outputImage;
    }
    
    int leftExtend =0;
    int rightExtend = 0;
    int topExtend = 0;
    int bottomExtend = 0;
    
    if(leftCropPointOnOriginalImage<0){
        leftExtend=0-leftCropPointOnOriginalImage;
        leftCropPointOnOriginalImage=0;
    }
    
    if(rightCropPointOnOriginalImage>originalWidth){
        rightExtend = rightCropPointOnOriginalImage-originalWidth;
        rightCropPointOnOriginalImage=originalWidth;
    }
    
    if(topCropPointOnOriginalImage<0){
        topExtend=0-topCropPointOnOriginalImage;
        topCropPointOnOriginalImage=0;
    }
    
    if(bottomCropPointOnOriginalImage>originalHeight){
        bottomExtend=bottomCropPointOnOriginalImage-originalHeight;
        bottomCropPointOnOriginalImage=originalHeight;
    }
    
    //crop on original image
    cv::Rect cropRect(leftCropPointOnOriginalImage,topCropPointOnOriginalImage,rightCropPointOnOriginalImage-leftCropPointOnOriginalImage,bottomCropPointOnOriginalImage-topCropPointOnOriginalImage);
    
    cv::Mat cropedMat = inputMat(cropRect);
    
    cv::Mat extendedMat = cropedMat;
    //extend
    if(leftExtend>0){
        cv::Mat leftExtendMat = cv::Mat(extendedMat.rows,leftExtend,CV_8UC4,transparentColor);
        cv::Mat mergedMat;
        cv::hconcat(leftExtendMat, extendedMat, mergedMat);
        extendedMat = mergedMat;
    }
    if(rightExtend>0){
        cv::Mat rightExtendMat = cv::Mat(extendedMat.rows,rightExtend,CV_8UC4,transparentColor);
        cv::Mat mergedMat;
        cv::hconcat(extendedMat, rightExtendMat, mergedMat);
        extendedMat = mergedMat;
    }
    
    if(topExtend>0){
        cv::Mat topExtendMat = cv::Mat(topExtend,extendedMat.cols,CV_8UC4,transparentColor);
        cv::Mat mergedMat;
        cv::vconcat(topExtendMat, extendedMat, mergedMat);
        extendedMat=mergedMat;
    }
    
    if(bottomExtend>0){
        cv::Mat bottomExtendMat = cv::Mat(bottomExtend,extendedMat.cols,CV_8UC4,transparentColor);
        cv::Mat mergedMat;
        cv::vconcat(extendedMat, bottomExtendMat, mergedMat);
        extendedMat=mergedMat;
    }
    
    // scale
    cv::Size newSize = cv::Size(originalWidth,originalHeight);
    cv::Mat outputMat;
    cv::resize(extendedMat, outputMat, newSize);
    
    UIImage* outputImage = UIImageFromCVMat(outputMat);
    
    return outputImage;
}

+ (UIImage *)padding:(UIImage *)image newRows:(int)newRows newCols:(int)newCols
{
    //return image;

    cv::Mat inputMat = cvMatFromUIImage(image);
    cv::Mat outputMat=padding(inputMat, newRows, newCols);
    
    // convert mat to image
    UIImage *outputImage = UIImageFromCVMat(outputMat);
    
    return outputImage;
    
}

cv::Mat padding(cv::Mat inputMat,int newRows,int newCols){
    int inputCols = inputMat.cols;
    int inputRows = inputMat.rows;
    
    cv::Mat outputMat = cv::Mat(inputMat);
    
    // padding horizontal
    //cv::Scalar transparentColor = cv::Scalar(255,255,255,255);
    
    int leftPaddingCols = (newCols - inputCols ) /2;
    int rightPaddingCols = newCols-inputCols-leftPaddingCols;
    
    if (leftPaddingCols>0){
        cv::Mat leftPaddingMat = cv::Mat(inputRows,leftPaddingCols,CV_8UC4,transparentColor);
        // merge
        cv::Mat mergedMat = cv::Mat();
        cv::hconcat(leftPaddingMat, inputMat, mergedMat);
        outputMat=mergedMat;
    }
    if(rightPaddingCols>0){
        cv::Mat rightPaddingMat = cv::Mat(inputRows,rightPaddingCols,CV_8UC4,transparentColor);
        //merge
        cv::Mat mergedMat = cv::Mat();
        cv::hconcat(outputMat, rightPaddingMat,mergedMat);
        outputMat=mergedMat;
    }
    
    // padding vertical
    int topPaddingRows = (newRows-outputMat.rows)/2;
    int bottomPaddingRows = newRows-outputMat.rows-topPaddingRows;
    
    if(topPaddingRows>0){
        cv::Mat topPaddingMat = cv::Mat(topPaddingRows,outputMat.cols,CV_8UC4,transparentColor);
        
        //merge
        cv::Mat mergedMat = cv::Mat();
        cv::vconcat(topPaddingMat, outputMat, mergedMat);
        outputMat=mergedMat;
    }
    
    if(bottomPaddingRows>0){
        cv::Mat bottomPaddingMat = cv::Mat(bottomPaddingRows,outputMat.cols,CV_8UC4,transparentColor);
        //merge
        cv::Mat mergedMat = cv::Mat();
        cv::vconcat(outputMat, bottomPaddingMat, mergedMat);
        outputMat=mergedMat;
    }
    
    return outputMat;
}

+(UIImage *) extend:(UIImage *)image topExtend:(int)topExtend rightExtend:(int)rightExtend bottomExtend:(int)bottomExtend leftExtend:(int)leftExtend{
    cv::Mat inputMat=cvMatFromUIImage(image);
    
    cv::Mat outputMat=inputMat;
    
    if(topExtend>0){
        cv::Mat topExtendMat = cv::Mat(topExtend,inputMat.cols,CV_8UC4,transparentColor);
        //merge
        cv::Mat mergedMat;
        cv::vconcat(topExtendMat,outputMat,mergedMat);
        outputMat=mergedMat;
    }
    
    if(rightExtend>0){
        cv::Mat rightExtendMat = cv::Mat(outputMat.rows,rightExtend,CV_8UC4,transparentColor);
        //merge
        cv::Mat mergedMat;
        cv::hconcat(outputMat,rightExtendMat,mergedMat);
        outputMat=mergedMat;
        
    }
    
    if(bottomExtend>0){
        cv::Mat bottomExtendMat = cv::Mat(bottomExtend,outputMat.cols,CV_8UC4,transparentColor);
        //merge
        cv::Mat mergedMat;
        cv::vconcat(outputMat,bottomExtendMat,mergedMat);
        outputMat=mergedMat;
    }
    
    if(leftExtend>0){
        cv::Mat leftExtendMat = cv::Mat(outputMat.rows,leftExtend,CV_8UC4,transparentColor);
        //merge
        cv::Mat mergedMat;
        cv::hconcat(leftExtendMat,outputMat,mergedMat);
        
        outputMat=mergedMat;
    }
    
    UIImage* outputImage = UIImageFromCVMat(outputMat);
    return outputImage;
}

+(UIImage *) zoom:(UIImage *)image scale:(float)scale {
    cv::Mat inputMat = cvMatFromUIImage(image);
    int originalRows = inputMat.rows;
    int originalCols = inputMat.cols;
    
   
    
    if(scale >=1.0){
        // for using lower memory, crop original image first and then resize
        
        // computated the left rect
        int leftRows = int(originalRows/scale);
        int leftCols = int(originalCols/scale);
        
        int leftStartRows = int((originalRows-leftRows)/2);
        int leftStartCols = int((originalCols-leftCols)/2);
        
        cv::Rect leftRect(leftStartCols,leftStartRows,leftCols,leftRows);
        
        cv::Mat leftMat = inputMat(leftRect);
        
        cv::Size newSize = cv::Size(originalCols,originalRows);
        
        cv::Mat outputMat;
        cv::resize(leftMat, outputMat, newSize);
        

        
        UIImage* outputImage = UIImageFromCVMat(outputMat);
        
        return outputImage;
    }else{
        // scale image
        
        int newRows = int(originalRows*scale);
        int newCols = int(originalCols*scale);
        
        cv::Size newSize = cv::Size(newCols,newRows);
        cv::Mat scaledMat;
        
        cv::resize(inputMat, scaledMat, newSize);
        
        // padding
        cv::Mat outputMat = padding(scaledMat, originalRows, originalCols);
        
        UIImage* outputImage = UIImageFromCVMat(outputMat);
        
        return outputImage;
    }
    
    

    
    
    
}


/*******************************
 * Filters
 *
 */

/***************************
 *
 * cartoonize filter. Make image looks like cartoon.
 * The process to produce the cartoon effect is divided into two branches- one for detecting and boldening the edges, and one for smoothing and quantizing the colors in the image. At the end, the resulting images are combined to archive the effect.
 *
 * this implementation accordinging to the algorithm described on https://stacks.stanford.edu/file/druid:yt916dh6570/Dade_Toonify.pdf.
 *
 */
+(UIImage *) cartoonizeFilter:(UIImage *)image{
    cv::Mat inputMat = cvMatFromUIImage(image);
    
    // 1. detecting and boldening the edges
    // 1.1 gray scale the image
    cv::Mat grayScaleMat;
    cv::cvtColor(inputMat, grayScaleMat, cv::COLOR_RGB2GRAY);
    
    // 1.2 median filter
    cv::Mat medianFilteredMat;
    int medianFilterKernelSize =7;
    cv::medianBlur(grayScaleMat,medianFilteredMat,medianFilterKernelSize);
    
    // 1.3 edge detection
    cv::Mat detectedEdgesMat;
    double lowThreshold=100;
    double highThreshold=300;
    cv::Canny(medianFilteredMat, detectedEdgesMat, lowThreshold, highThreshold);
    
    // 1.4 morphological operations
    // TODO skip
    cv::Mat boldenEdgesMat;
    cv::morphologyEx(detectedEdgesMat, boldenEdgesMat, cv::MORPH_OPEN, cv::getStructuringElement(cv::MORPH_RECT, cv::Size(2,2)));
    // 1.5 edge filter
    // TODO skip
    
    cv::Mat edgesMat = boldenEdgesMat;
    
    // 2 smoothing and quantizing colors
    
    // 2.1 Bilateral filter
    
    cv::Mat bilateralFilteredMat;
    cv::cvtColor(inputMat, bilateralFilteredMat, CV_BGRA2RGB);
    
    for(int i=0;i<14;i++){
        cv::Mat destMat =bilateralFilteredMat.clone();
        cv::bilateralFilter(bilateralFilteredMat, destMat, 9, 9*2, 9/2);
        
        bilateralFilteredMat=destMat;
    }
    
    cv::resize(bilateralFilteredMat, bilateralFilteredMat, cv::Size(inputMat.cols,inputMat.rows));
    
    
    // 2.2 median filter
    cv::Mat medianFilteredColorMat;
    int colorMedianFilterKernelSize =7;
    cv::medianBlur(bilateralFilteredMat,medianFilteredColorMat,colorMedianFilterKernelSize);
    
    // 2.3 quantize colors
    /*
    int originalWidth = medianFilteredColorMat.cols;
    int originalHeight = medianFilteredColorMat.rows;
    
    cv::Mat quantizedMat =medianFilteredColorMat;
    quantizedMat.reshape(-1,3);
    quantizedMat.convertTo(quantizedMat, CV_32F);
    int kernel = 4;
    cv::TermCriteria criteria = cv::TermCriteria(CV_TERMCRIT_EPS + CV_TERMCRIT_ITER, 10, 1.0);
    cv::Mat clusterMat = cvCreateMat(medianFilteredColorMat.cols*medianFilteredColorMat.rows, 1, CV_32SC1);
    cv::Mat centerMat;
    cv::kmeans(quantizedMat, kernel, clusterMat, criteria, 10, cv::KMEANS_RANDOM_CENTERS,centerMat);
     clusterMat.reshape(0,originalHeight);
     centerMat.reshape(0,originalHeight);
     cv::convertScaleAbs(clusterMat, clusterMat,int(255/kernel));
     cv::convertScaleAbs(centerMat, centerMat,int(255/kernel));
    */
    int colorCount = 24;
    
    cv::Mat quantizedMat =medianFilteredColorMat;
    quantizedMat.convertTo(quantizedMat, CV_8UC3);
    quantizedMat = quantizedMat /colorCount;
    quantizedMat = quantizedMat *colorCount;

    
    
    
    // 3 recombine
    cv::Mat resultMat=quantizedMat.clone();
    //cv::Mat mask = cv::Mat(edgesMat.size(),CV_8UC3,cv::Scalar(0));
    //cv::drawContours(mask, edgesMat, -1, cv::Scalar(255));
    //edgesMat.copyTo(resultMat,mask);
    cv::Mat edgesPrint = cv::Mat(edgesMat.rows,edgesMat.cols,CV_8UC3,cv::Scalar(0,0,0));
    edgesPrint.copyTo(resultMat, edgesMat);
    
    UIImage* outputImage = UIImageFromCVMat(resultMat);
    return outputImage;
}

//type converter

cv::Mat cvMatFromUIImage(UIImage* image)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

UIImage* UIImageFromCVMat(cv::Mat cvMat)
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}



@end
