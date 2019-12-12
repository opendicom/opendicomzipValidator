# opendicomzipValidator
verifies if a file complies with the opendicomzip format (which is a valid but more limited iso zip)

Based on the APPNOTE.TXT .ZIP File Format Specification version 6.3.6 (April 26, 2019), restricted according to ISO_IEC_21320-1_2015, y further constrained by jacquesfauquex@gmail.com for use with the opendicom implementation of dicomzip.

WORK IN PROGRESS

4.1 What is a ZIP file
----------------------

**4.1.3** Data compression MAY be used to reduce the size of files placed into a ZIP file, but is not required. Compression method 8 (Deflate) is the method used by default by most ZIP compatible application programs.  

**4.1.5** Data integrity MUST be provided for each file using CRC32.  

**4.1.12** ZIP files MAY be placed within other ZIP files.


4.2 ZIP Metadata
----------------

**4.2.1** ZIP files are identified by metadata consisting of defined record types containing the storage information necessary for maintaining the files placed into a ZIP file.  Each record type MUST be identified using a header signature that identifies the record type.  Signature values begin with the two byte constant marker of 0x4b50, representing the characters "PK".


4.3 General Format of a .ZIP file
---------------------------------

**4.3.1** A ZIP file MUST contain an "end of central directory record". A ZIP file containing only an **"end of central directory record"** is considered an empty ZIP file.  Files MAY be added or replaced within a ZIP file, or deleted. A ZIP file MUST have only one **"end of central directory record"**.  Other records defined in this specification MAY be used as needed to support storage requirements for individual ZIP files.

**4.3.2** Each file placed into a ZIP file MUST be preceeded by  a **"local file header"** record for that file.  Each "local file header" MUST be accompanied by a corresponding **"central directory header"** record within the central directory section of the ZIP file.

**4.3.4** Compression MUST NOT be applied to a "local file header" or an "end of central directory record".  Individual "central directory records" MUST NOT be compressed, but the aggregate of all central directory records MAY be compressed.    

**4.3.6** Overall .ZIP file format

      [local file header 1]
      [file data 1]
      . 
      .
      .
      [local file header n]
      [file data n]
      [central directory header 1]
      .
      .
      .
      [central directory header n]
      [zip64 end of central directory record]
      [zip64 end of central directory locator] 
      [end of central directory record]


**4.3.7**  Local file header

      local file header signature     4 bytes  (0x04034b50)
      version needed to extract       2 bytes
      general purpose bit flag        2 bytes
      compression method              2 bytes
      last mod file time              2 bytes
      last mod file date              2 bytes
      crc-32                          4 bytes
      compressed size                 4 bytes
      uncompressed size               4 bytes
      file name length                2 bytes
      extra field length              2 bytes  =0

      file name                      36 bytes

**4.3.8**  File data

- Immediately following the local header for a file SHOULD be placed the compressed or stored data for the file.
- The series of [local file header][encryption header][file data][data descriptor] repeats for each file in the .ZIP archive. 
- Zero-byte files, directories, and other file types that contain no content MUST NOT include file data.

**4.3.12**  Central directory structure:

      [central directory header 1]
      .
      .
      . 
      [central directory header n]

      File header:

        central file header signature   4 bytes  (0x02014b50)
        version made by                 2 bytes
        version needed to extract       2 bytes
        general purpose bit flag        2 bytes
        compression method              2 bytes
        last mod file time              2 bytes
        last mod file date              2 bytes
        crc-32                          4 bytes
        compressed size                 4 bytes
        uncompressed size               4 bytes
        file name length                2 bytes
        extra field length              2 bytes =0
        file comment length             2 bytes =0
        disk number start               2 bytes
        internal file attributes        2 bytes
        external file attributes        4 bytes
        relative offset of local header 4 bytes
        file name                      36 bytes

        
**4.3.16**  End of central directory record

      end of central dir signature    4 bytes  (0x06054b50)
      number of this disk             2 bytes  =0
      number of the disk with the
      start of the central directory  2 bytes  =0
      total number of entries in the
      central directory on this disk  2 bytes
      total number of entries in
      the central directory           2 bytes
      size of the central directory   4 bytes
      offset of start of central
      directory with respect to
      the starting disk number        4 bytes
      .ZIP file comment length        2 bytes =0
                
4.4  Explanation of fields
--------------------------
      
**4.4.1** General notes on fields

**4.4.1.1**  All fields unless otherwise noted are unsigned and stored in Intel low-byte:high-byte, low-word:high-word order.

**4.4.1.2**  String fields are not null terminated, since the length is given explicitly.

**4.4.1.3**  The entries in the central directory MAY NOT necessarily be in the same order that files appear in the .ZIP file.

**4.4.2** version made by (2 bytes)

**4.4.2.1** The upper byte indicates the compatibility of the file attribute information.  If the external file attributes are compatible with MS-DOS and can be read by PKZIP for DOS version 2.04g then this value will be zero.  If these attributes are not compatible, then this value will identify the host system on which the attributes are compatible.  Software can use this information to determine the line record format for text files etc.  

**4.4.2.2** The current mappings are:

         0 - MS-DOS and OS/2 (FAT / VFAT / FAT32 file systems)
         3 - UNIX                      
         7 - Macintosh                 
        10 - Windows NTFS
        19 - OS X (Darwin)            
        20 thru 255 - unused

**4.4.2.3** The lower byte indicates the ZIP specification version (the version of this document) supported by the software used to encode the file.  The value/10 indicates the major version number, and the value mod 10 is the minor version number.  

**4.4.3** version needed to extract (2 bytes)

**4.4.3.1** The minimum supported ZIP specification version needed to extract the file, mapped as above.  This value is based on the specific format features a ZIP program MUST support to be able to extract the file.  If multiple features are applied to a file, the minimum version MUST be set to the feature having the highest value. New features or feature changes affecting the published format specification will be implemented using higher version numbers than the last published value to avoid conflict.

**4.4.3.2** Current minimum feature versions are as defined below:

```
    0x0A,0x00  1.0 - Default value
    0x14,0x00  2.0 - File is compressed using Deflate compression
```

When using ZIP64 extensions, the corresponding value in the zip64 end of central directory record MUST also be set. This field SHOULD be set appropriately to indicate whether Version 1 or Version 2 format is in use. 


**4.4.4** general purpose bit flag: (2 bytes)

    Bit 0: 0

    Bit 2  Bit 1
    0      0    Normal (-en) compression option was used.
    0      1    Maximum (-exx/-ex) compression option was used.
    1      0    Fast (-ef) compression option was used.
    1      1    Super Fast (-es) compression option was used.


        Bit 3 : 0
        Bit 4 : 0 
        Bit 5 : 0
        Bit 6 : 0
        Bit 7 : 0
        Bit 8 : 0
        Bit 9 : 0
        Bit 10: 0

        Bit 11: Language encoding flag (EFS).  If this bit is set,
                the filename and comment fields for this file
                MUST be encoded using UTF-8. (see APPENDIX D)
```
If the value of any byte in the file name or file comment is greater than 0x7F, bit 11 shall be set.

If bit 11 is set the file names and comment fields for the document container file shall be Unicode strings encoded using the UTF-8 encoding scheme as specified in ISO/IEC 10646:2014, Annex D.
```


        Bit 12: 0
        Bit 13: 0
        Bit 14: 0
        Bit 15: 0

4.4.5 compression method: (2 bytes)

        0 - The file is stored (no compression)
        8 - The file is Deflated

4.4.6 date and time fields: (2 bytes each)

       The date and time are encoded in standard MS-DOS format.
       If input came from standard input, the date and time are
       those at which compression was started for this data. 
       If encrypting the central directory and general purpose bit 
       flag 13 is set indicating masking, the value stored in the 
       Local Header will be zero. MS-DOS time format is different
       from more commonly used computer time formats such as 
       UTC. For example, MS-DOS uses year values relative to 1980
       and 2 second precision.

4.4.7 CRC-32: (4 bytes)

       The CRC-32 algorithm was generously contributed by
       David Schwaderer and can be found in his excellent
       book "C Programmers Guide to NetBIOS" published by
       Howard W. Sams & Co. Inc.  The 'magic number' for
       the CRC is 0xdebb20e3.  The proper CRC pre and post
       conditioning is used, meaning that the CRC register
       is pre-conditioned with all ones (a starting value
       of 0xffffffff) and the value is post-conditioned by
       taking the one's complement of the CRC residual.
       If bit 3 of the general purpose flag is set, this
       field is set to zero in the local header and the correct
       value is put in the data descriptor and in the central
       directory. When encrypting the central directory, if the
       local header is not in ZIP64 format and general purpose 
       bit flag 13 is set indicating masking, the value stored 
       in the Local Header will be zero. 

4.4.8 compressed size: (4 bytes)
4.4.9 uncompressed size: (4 bytes)

       The size of the file compressed (4.4.8) and uncompressed,
       (4.4.9) respectively.  When a decryption header is present it 
       will be placed in front of the file data and the value of the
       compressed file size will include the bytes of the decryption
       header.  If bit 3 of the general purpose bit flag is set, 
       these fields are set to zero in the local header and the 
       correct values are put in the data descriptor and
       in the central directory.  If an archive is in ZIP64 format
       and the value in this field is 0xFFFFFFFF, the size will be
       in the corresponding 8 byte ZIP64 extended information 
       extra field.  When encrypting the central directory, if the
       local header is not in ZIP64 format and general purpose bit 
       flag 13 is set indicating masking, the value stored for the 
       uncompressed size in the Local Header will be zero. 

4.4.10 file name length: (2 bytes)

       The length of the file name. If input came from standard
       input, the file name length is set to zero.  

4.4.13 disk number start: (2 bytes) =0

4.4.14 internal file attributes: (2 bytes)

       Bits 1 and 2 are reserved for use by PKWARE.

       4.4.14.1 The lowest bit of this field indicates, if set, 
       that the file is apparently an ASCII or text file.  If not
       set, that the file apparently contains binary data.
       The remaining bits are unused in version 1.0.

       4.4.14.2 The 0x0002 bit of this field indicates, if set, that 
       a 4 byte variable record length control field precedes each 
       logical record indicating the length of the record. The 
       record length control field is stored in little-endian byte
       order.  This flag is independent of text control characters, 
       and if used in conjunction with text data, includes any 
       control characters in the total length of the record. This 
       value is provided for mainframe data transfer support.

4.4.15 external file attributes: (4 bytes)

       The mapping of the external attributes is
       host-system dependent (see 'version made by').  For
       MS-DOS, the low order byte is the MS-DOS directory
       attribute byte.  If input came from standard input, this
       field is set to zero.

4.4.16 relative offset of local header: (4 bytes)

       This is the offset from the start of the first disk on
       which this file appears, to where the local header SHOULD
       be found.  If an archive is in ZIP64 format and the value
       in this field is 0xFFFFFFFF, the size will be in the 
       corresponding 8 byte zip64 extended information extra field.

4.4.17 file name: (Variable)

       4.4.17.1 The name of the file, with optional relative path.
       The path stored MUST NOT contain a drive or
       device letter, or a leading slash.  All slashes
       MUST be forward slashes '/' as opposed to
       backwards slashes '\' for compatibility with Amiga
       and UNIX file systems etc.  If input came from standard
       input, there is no file name field.  

       4.4.17.2 If using the Central Directory Encryption Feature and 
       general purpose bit flag 13 is set indicating masking, the file 
       name stored in the Local Header will not be the actual file name.  
       A masking value consisting of a unique hexadecimal value will 
       be stored.  This value will be sequentially incremented for each 
       file in the archive. See the section on the Strong Encryption 
       Specification for details on retrieving the encrypted file name. 
       Refer to the section in this document entitled "Incorporating PKWARE 
       Proprietary Technology into Your Product" for more information.


4.4.21 total number of entries in the central dir on this disk: (2 bytes)
4.4.22 total number of entries in the central dir: (2 bytes)

      The total number of files in the .ZIP file. 

4.4.23 size of the central directory: (4 bytes)

      The size (in bytes) of the entire central directory.

4.4.24 offset of start of central directory with respect to the starting disk number:  (4 bytes)

      Offset of the start of the central directory on the
      disk on which the central directory starts.

5.5 Deflating - Method 8
------------------------

```
Files compressed using this method shall use the mechanisms specified in IETF RFC 1951
```


APPENDIX D - Language Encoding (EFS)
------------------------------------

D.1 The ZIP format has historically supported only the original IBM PC character 
encoding set, commonly referred to as IBM Code Page 437.  This limits storing 
file name characters to only those within the original MS-DOS range of values 
and does not properly support file names in other character encodings, or 
languages. To address this limitation, this specification will support the 
following change. 

D.2 If general purpose bit 11 is unset, the file name and comment SHOULD conform 
to the original ZIP character encoding.  If general purpose bit 11 is set, the 
filename and comment MUST support The Unicode Standard, Version 4.1.0 or 
greater using the character encoding form defined by the UTF-8 storage 
specification.  The Unicode Standard is published by the The Unicode
Consortium (www.unicode.org).  UTF-8 encoded data stored within ZIP files 
is expected to not include a byte order mark (BOM). 

D.3 Applications MAY choose to supplement this file name storage through the use 
of the 0x0008 Extra Field.  Storage for this optional field is currently 
undefined, however it will be used to allow storing extended information 
on source or target encoding that MAY further assist applications with file 
name, or file content encoding tasks.  Please contact PKWARE with any
requirements on how this field SHOULD be used.

D.4 The 0x0008 Extra Field storage MAY be used with either setting for general 
purpose bit 11.  Examples of the intended usage for this field is to store 
whether "modified-UTF-8" (JAVA) is used, or UTF-8-MAC.  Similarly, other 
commonly used character encoding (code page) designations can be indicated 
through this field.  Formalized values for use of the 0x0008 record remain 
undefined at this time.  The definition for the layout of the 0x0008 field
will be published when available.  Use of the 0x0008 Extra Field provides
for storing data within a ZIP file in an encoding other than IBM Code
Page 437 or UTF-8.

D.5 General purpose bit 11 will not imply any encoding of file content or
password.  Values defining character encoding for file content or 
password MUST be stored within the 0x0008 Extended Language Encoding 
Extra Field.

D.6 Ed Gordon of the Info-ZIP group has defined a pair of "extra field" records 
that can be used to store UTF-8 file name and file comment fields.  These
records can be used for cases when the general purpose bit 11 method
for storing UTF-8 data in the standard file name and comment fields is
not desirable.  A common case for this alternate method is if backward
compatibility with older programs is required.

D.7 Definitions for the record structure of these fields are included above 
in the section on 3rd party mappings for "extra field" records.  These
records are identified by Header ID's 0x6375 (Info-ZIP Unicode Comment 
Extra Field) and 0x7075 (Info-ZIP Unicode Path Extra Field).

D.8 The choice of which storage method to use when writing a ZIP file is left
to the implementation.  Developers SHOULD expect that a ZIP file MAY 
contain either method and SHOULD provide support for reading data in 
either format. Use of general purpose bit 11 reduces storage requirements 
for file name data by not requiring additional "extra field" data for
each file, but can result in older ZIP programs not being able to extract 
files.  Use of the 0x6375 and 0x7075 records will result in a ZIP file 
that SHOULD always be readable by older ZIP programs, but requires more 
storage per file to write file name and/or file comment fields.

