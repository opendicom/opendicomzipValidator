#import <Foundation/Foundation.h>
#import "ODLog.h"
int main(int argc, const char * argv[]) {
   @autoreleasepool {
      
      LOG_INFO(@"%d",(uint32)[[[@"0000001424.4224027299.0000526048.dcm" stringByDeletingPathExtension]pathExtension]intValue]);
      NSArray *args=[[NSProcessInfo processInfo] arguments];

      NSFileManager *fileManager=[NSFileManager defaultManager];
      
      if (args.count < 2)
      {
         LOG_ERROR(@"requires arg1: path to zip file");
         return 0;
      }
      
      if (args.count >2)
      {
         NSUInteger llindex=[@[@"DEBUG",@"VERBOSE",@"INFO",@"WARNING",@"ERROR",@"EXCEPTION"] indexOfObject:args[2]];
         if (llindex==NSNotFound)
         {
             LOG_ERROR(@"ODLogLevel (arg 2) should be one of [ DEBUG | VERBOSE | INFO | WARNING | ERROR | EXCEPTION ]");
             return 1;
         }
         ODLogLevel=(int)llindex;
      }
      
      NSString *path=[args[1] stringByExpandingTildeInPath];
      if (![fileManager fileExistsAtPath:path isDirectory:false])
      {
         NSLog(@"can not find zip file %@",path);
         return 0;
      }
      
      NSData *data=[NSData dataWithContentsOfFile:path];
      if (!data)
      {
          NSLog(@"can not read zip file %@",path);
          return 0;
      }
      LOG_INFO(@"path: %@", path);
      unsigned long length=data.length;
      LOG_INFO(@"length: %lu", length);
      
#pragma mark epilog
      NSData *epilogData=[data subdataWithRange:NSMakeRange(length-22,22)];
      //NSLog(@"%@",[epilog description]);
      struct epilog
      {
         uint32 tag;
         uint16 diskNumber;
         uint16 diskStarts;
         uint16 diskEntries;
         uint16 totalEntries;
         uint32 centralSize;
         uint32 centralPointer;
         uint16 extraLength;
      } __attribute__((packed));
      const struct epilog* Epilog=(const struct epilog*)[epilogData bytes];

      if (Epilog->tag==0x06054b50) LOG_DEBUG(@"Epilog tag OK");
      else LOG_ERROR(@"Epilog tag: %04x",Epilog->tag);
      LOG_INFO(@"entries: %d\r\n==========",Epilog->totalEntries);
      
#pragma mark central
      
      struct central
      {
         uint32 tag;
         uint16 madeBy;
         uint16 version;
         uint16 flag;
         uint16 compressionCode;
         uint16 time;
         uint16 date;
         uint32 CRC32;
         uint32 compressedSize;
         uint32 uncompressedSize;
         uint16 nameLength;
         uint16 extraLength;
         uint16 commentLength;
         uint16 diskNumber;
         uint16 internalFileAttribute;
         uint32 externalFileAttribute;
         uint32 localPointer;
         char  name[36];
      } __attribute__((packed));
 
      if (Epilog->centralSize != (82 * Epilog->totalEntries))
      {
         LOG_ERROR(@"central size %d should be 82 * %d",Epilog->centralSize,Epilog->totalEntries);
         return 0;
      }
      
      for (int i = 0; i < Epilog->totalEntries; i++)
      {
         LOG_DEBUG(@"%d ---------",i);
         NSRange centralMetaDataRange=NSMakeRange(Epilog->centralPointer + (i *       82),82);
         NSData *centralMetaData=[data subdataWithRange:centralMetaDataRange];
         LOG_DEBUG(@"central metadata offset:%lu length:%lu %@",(unsigned long)centralMetaDataRange.location,(unsigned long)centralMetaDataRange.length,[centralMetaData description]);

         const struct central* Central=(const struct central*)[centralMetaData bytes];
         
         if (Central->tag!=0x02014b50) LOG_ERROR(@"Central tag should be 0x02014b50");

         
#pragma mark local
         
         struct local
         {
            uint32 tag;
            uint16 version;
            uint16 flag;
            uint16 compressionCode;
            uint16 time;
            uint16 date;
            uint32 CRC32;
            uint32 compressedSize;
            uint32 uncompressedSize;
            uint16 nameLength;
            uint16 extraLength;
            char  name[36];
         } __attribute__((packed));

         NSRange localMetaDataRange=NSMakeRange(Central->localPointer,66);
         NSData *localMetaData=[data subdataWithRange:localMetaDataRange];
         LOG_DEBUG(@"local metadata offset:%lu length:%lu %@",(unsigned long)localMetaDataRange.location,(unsigned long)localMetaDataRange.length,[localMetaData description]);

         const struct local* Local=(const struct local*)[localMetaData bytes];
         
         if (Local->tag!=0x04034b50) LOG_ERROR(@"Central tag should be 0x04034b50");

         LOG_VERBOSE(@"local info for item %d\r\n       version          %d\r\n       flag             %d\r\n       compressionCode  %d\r\n       time             %d\r\n       date             %d\r\n       CRC32            %d\r\n       compressedSize   %d\r\n       uncompressedSize %d\r\n       nameLength       %d\r\n       extraLength      %d\r\n       name             %s",
                     i,
                     Local->version,
                     Local->flag,
                     Local->compressionCode,
                     Local->time,
                     Local->date,
                     Local->CRC32,
                     Local->compressedSize,
                     Local->uncompressedSize,
                     Local->nameLength,
                     Local->extraLength,
                     Local->name);
         
         if (Central->version != Local->version) LOG_WARNING(@"central version %d",Central->version);
         if (Central->flag != Local->flag) LOG_WARNING(@"central flag %d",Central->flag);
         if (Central->time != Local->time) LOG_WARNING(@"central time %d",Central->flag);
         if (Central->date != Local->date) LOG_WARNING(@"central date, %d",Central->date);
         if (Central->CRC32 != Local->CRC32) LOG_WARNING(@"central CRC32 %d",Central->CRC32);
         
         uint32 cc=Central->compressedSize;
         uint32 lc=Local->compressedSize;
         if (cc != lc) LOG_WARNING(@"central compressedSize %d",cc);
         uint32 cu=Central->uncompressedSize;
         uint32 lu=Local->uncompressedSize;
         if (cu != lu) LOG_WARNING(@"central uncompressedSize %d",cu);
         
         if (Central->nameLength != Local->nameLength) LOG_WARNING(@"central nameLength %d",Central->nameLength);
         if (Central->extraLength != Local->extraLength) LOG_WARNING(@"central extraLength %d",Central->extraLength);
         
         if(strncmp(Central->name, Local->name, sizeof(Central->name)) != 0) LOG_WARNING(@"central name '%s'",Central->name);



#pragma mark file
         UInt32 fileOffset=Central->localPointer+66;
         LOG_DEBUG(@"file offset %d and size %d",fileOffset,Local->compressedSize);
         NSRange fileRange=NSMakeRange(fileOffset,Local->compressedSize);
         uint32 nextLocalTag=0;
         [data getBytes:&nextLocalTag range:NSMakeRange(fileOffset + Local->compressedSize,4)];
         if (Local->tag==0x04034b50) LOG_INFO(@"%d  file(%d,%d)",i,fileOffset,Local->compressedSize);
         else LOG_ERROR(@"%d bad file size. Next tag should start at %d",i,Central->localPointer + 66 + Local->compressedSize);

      }


   }
   LOG_INFO(@"===========\r\n    END PARSING");
   return 0;
}
