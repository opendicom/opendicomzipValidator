#import <Foundation/Foundation.h>
#import "ODLog.h"
int main(int argc, const char * argv[]) {
   @autoreleasepool {
      
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
      LOG_INFO(@"path   : %@", path);
      unsigned long length=data.length;
      LOG_INFO(@"length : %lu", length);
      if (length<22)
      {
         LOG_ERROR(@"no end");
         return 0;
      }
      
#pragma mark end
      uint32 endOffset=(uint32)length-22;
      NSData *endData=[data subdataWithRange:NSMakeRange(endOffset,22)];
      LOG_DEBUG(@"end metadata (%d,22) %@",endOffset,[endData description]);
      struct end
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
      const struct end* End=(const struct end*)[endData bytes];

      if (End->tag==0x06054b50) LOG_DEBUG(@"end tag OK");
      else LOG_ERROR(@"end tag: %04x",End->tag);

      if (   (End->centralPointer < 0)
          || (End->centralPointer + End->centralSize > length)
          || (End->centralSize < (46 * End->totalEntries))
          )
      {
         LOG_ERROR(@"central(%d,%d) %d entries",End->centralPointer, End->centralSize, End->totalEntries);
         return 0;
      }
      LOG_INFO(@"central(%d,%d) %d entries\r\n======================",End->centralPointer, End->centralSize, End->totalEntries);
           
      

#pragma mark - central loop
      
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
         char  name[];
      } __attribute__((packed));
      
      uint32 nextCentralOffset=End->centralPointer;
      uint16 nextNameLength=0;
      [data getBytes:&nextNameLength range:NSMakeRange(nextCentralOffset+28,2)];

      
      for (int i = 0; i < End->totalEntries; i++)
      {
         LOG_DEBUG(@"------------------");
         NSRange centralMetaDataRange=NSMakeRange(nextCentralOffset,46+nextNameLength);
         NSData *centralMetaData=[data subdataWithRange:centralMetaDataRange];
         LOG_DEBUG(@"%d central(%lu,%lu) %@",i,(unsigned long)centralMetaDataRange.location,(unsigned long)centralMetaDataRange.length,[centralMetaData description]);

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
            char  name[];
         } __attribute__((packed));

         NSRange localMetaDataRange=NSMakeRange(Central->localPointer,30 + nextNameLength);
         NSData *localMetaData=[data subdataWithRange:localMetaDataRange];
         LOG_DEBUG(@"%d local(%lu,%lu) %@",i,(unsigned long)localMetaDataRange.location,(unsigned long)localMetaDataRange.length,[localMetaData description]);

         const struct local* Local=(const struct local*)[localMetaData bytes];
         
         if (Local->tag!=0x04034b50) LOG_ERROR(@"local tag should be 0x04034b50");

         LOG_VERBOSE(@"%d\r\n   version          %d\r\n   flag             %d\r\n   compressionCode  %d\r\n   time             %d\r\n   date             %d\r\n   CRC32            %d\r\n   compressedSize   %d\r\n   uncompressedSize %d\r\n   nameLength       %d\r\n   extraLength      %d",
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
                     Local->extraLength);
         
         if (Central->version != Local->version) LOG_WARNING(@"central version %d",Central->version);
         if (Central->flag != Local->flag) LOG_WARNING(@"central flag %d",Central->flag);
         if (Central->time != Local->time) LOG_WARNING(@"central time %d",Central->flag);
         if (Central->date != Local->date) LOG_WARNING(@"central date, %d",Central->date);
         if (Central->CRC32 != Local->CRC32) LOG_WARNING(@"central CRC32 %d",Central->CRC32);
         if (Central->compressedSize != Local->compressedSize) LOG_WARNING(@"central compressedSize %d",Central->compressedSize);
         if (Central->uncompressedSize != Local->uncompressedSize) LOG_WARNING(@"central uncompressedSize %d",Central->uncompressedSize);
         
         if (Central->nameLength != Local->nameLength) LOG_WARNING(@"central nameLength %d",Central->nameLength);
         if (Central->extraLength != Local->extraLength) LOG_WARNING(@"central extraLength %d",Central->extraLength);
         
         if(strncmp(Central->name, Local->name, nextNameLength) != 0) LOG_WARNING(@"central name '%s'",Central->name);



#pragma mark file
         UInt32 fileOffset=Central->localPointer + 30 + nextNameLength;
         NSRange fileRange=NSMakeRange(fileOffset,Local->compressedSize);
         uint32 nextLocalTag=0;
         [data getBytes:&nextLocalTag range:NSMakeRange(fileOffset + Local->compressedSize,4)];
         LOG_INFO(@"%d file(%d,%d)%s",i,fileOffset,Local->compressedSize,Local->name);
         if (Local->tag!=0x04034b50) LOG_ERROR(@"%d bad file size. Next tag should start at %d",i, fileOffset + Local->compressedSize);

#pragma mark next
         nextCentralOffset=(uint32)(centralMetaDataRange.location + centralMetaDataRange.length);
         if (nextCentralOffset < endOffset) [data getBytes:&nextNameLength range:NSMakeRange(nextCentralOffset+28,2)];
      }
#pragma mark - epilog


   }
   LOG_INFO(@"======================\r\n    END PARSING");
   return 0;
}
