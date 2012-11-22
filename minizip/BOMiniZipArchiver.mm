//
//  BOMiniZipArchiver.m
//  minizip
//
//  Created by Daniel Eggert on 11/22/12.
//  Copyright (c) 2012 Daniel Eggert. All rights reserved.
//

#import "BOMiniZipArchiver.h"

#import "zip.h"
#import <unistd.h>
#import <utime.h>
#import <sys/types.h>
#import <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <fcntl.h>


@interface NSError (BOMiniZip)

+ (instancetype)errorWithZipErrorCode:(int)code descriptionFormat:(NSString *)format, ...;

@end


static void filetimeAndSize(NSURL *fileURL,
                            tm_zip &tmzip,
                            size_t &filesize)
{
    NSError *error = nil;
    NSDate *modificationTime = nil;
    if ([fileURL getResourceValue:&modificationTime forKey:NSURLContentModificationDateKey error:&error]) {
        time_t const tm_t = [modificationTime timeIntervalSince1970];
        struct tm * filedate = localtime(&tm_t);
        tmzip.tm_sec  = filedate->tm_sec;
        tmzip.tm_min  = filedate->tm_min;
        tmzip.tm_hour = filedate->tm_hour;
        tmzip.tm_mday = filedate->tm_mday;
        tmzip.tm_mon  = filedate->tm_mon ;
        tmzip.tm_year = filedate->tm_year;
    } else {
        NSLog(@"Unable to get modification time for \"%@\"", [fileURL path]);
    }
    NSNumber *wrappedSize = nil;
    if ([fileURL getResourceValue:&wrappedSize forKey:NSURLFileSizeKey error:&error]) {
        filesize = [wrappedSize longLongValue];
    } else {
        filesize = 0LL;
    }
}







@implementation BOMiniZipArchiver
{
    zipFile _zf;
}

- (id)init
{
    return nil;
}

- (id)initWithFileURL:(NSURL *)outputURL append:(BOOL)shouldAppend error:(NSError **)error;
{
    self = [super init];
    if (self) {
        
        if (shouldAppend &&
            ![[NSFileManager defaultManager] fileExistsAtPath:[outputURL path]])
        {
            shouldAppend = NO;
        }
        
        _zf = zipOpen64([[outputURL path] fileSystemRepresentation], shouldAppend ? 2 : 0);
        if (_zf == NULL) {
            if (error != NULL) {
                *error = [NSError errorWithZipErrorCode:ZIP_ERRNO descriptionFormat:@"Error opening %@", [outputURL path]];
            }
            return nil;
        }
    }
    return self;
}

- (BOOL)appendFileAtURL:(NSURL *)fileURL error:(NSError **)error;
{
    if (_zf == NULL) {
        return NO;
    }
    
    zip_fileinfo zi = {};
    size_t filesize = 0;
    filetimeAndSize(fileURL, zi.tmz_date, filesize);
    
    char const * const password = NULL;
    
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedAlways error:error];
    if (fileData == nil) {
        return NO;
    }
    
    unsigned long crcFile = 0;
    int err = ZIP_OK;
    if ((password != NULL) && (err == ZIP_OK)) {
        // Because to encrypt a file, we need known the CRC32 of the file before
        crcFile = crc32(0, (const Bytef *) [fileData bytes], (uInt) [fileData length]);
    }
    
    BOOL const zip64 = (0xffffffff <= filesize);
    
    NSString * const filenameinzip = [fileURL lastPathComponent];
    
    int const level = 1;
    int const method = (level != 0) ? Z_DEFLATED : 0;
    
    err = zipOpenNewFileInZip3_64(_zf, [filenameinzip fileSystemRepresentation], &zi,
                                  NULL, 0, NULL, 0, NULL /* comment*/,
                                  method, level, 0,
                                  -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
                                  password, crcFile, zip64);
    
    if (err != ZIP_OK) {
        if (error != nil) {
            *error = [NSError errorWithZipErrorCode:err descriptionFormat:@"Error while opening new file '%@' in zip archive.", filenameinzip];
        }
        return NO;
    } else {
        err = zipWriteInFileInZip(_zf, (const Bytef *) [fileData bytes], (uInt) [fileData length]);
        if (err < 0) {
            if (error != NULL) {
                *error = [NSError errorWithZipErrorCode:err descriptionFormat:@"Error while writing '%@' to the zipfile", filenameinzip];
            }
        }
    }
    
    if (err == ZIP_OK) {
        err = zipCloseFileInZip(_zf);
        if (err != ZIP_OK) {
            if (error != NULL) {
                *error = [NSError errorWithZipErrorCode:err descriptionFormat:@"Error while closing '%@' in the zipfile", filenameinzip];
            }
            return NO;
        }
    }
    return YES;
}

- (BOOL)finishEncoding:(NSError **)error;
{
    if (_zf == NULL) {
        return NO;
    }
    int err = zipClose(_zf, NULL);
    _zf = NULL;
    if (err != ZIP_OK) {
        if (error != NULL) {
            *error = [NSError errorWithZipErrorCode:err descriptionFormat:@"Error while closing zipfile"];
        }
        return NO;
    }
    return YES;
}

- (void)dealloc;
{
    [self finishEncoding:NULL];
}

@end
