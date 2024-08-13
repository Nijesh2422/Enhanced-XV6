#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <sys/time.h>
typedef struct Numberofpackets
{
    int numberofpackets;
} Numberofpackets;
typedef struct Acknum
{
    int numbeofpackets;
} Acknum;
typedef struct Datapackets
{
    int index;
    char Data[15];
    time_t time;
} Datapackets;
typedef struct Acknowledgements
{
    int index;
} Acknowledgements;
int main()
{
    int sockfdc = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sockfdc < 0)
    {
        printf("Socket Creation Failed\n");
        exit(1);
    }

    struct sockaddr_in ServerAddressPort;
    ServerAddressPort.sin_port = htons(5100);
    ServerAddressPort.sin_family = AF_INET;
    ServerAddressPort.sin_addr.s_addr = inet_addr("127.0.0.1");

    // while (1)
    // {
    printf("You: ");
    char Buffer[4096];
    fgets(Buffer, sizeof(Buffer), stdin);
    int Buflen = strlen(Buffer);
    int remainder = Buflen % 15;
    int numberofpackets;
    if (remainder == 0)
    {
        numberofpackets = Buflen / 15;
    }
    else
    {
        numberofpackets = (Buflen / 15) + 1;
    }

    Numberofpackets PackNos;
    Acknum A;
    A.numbeofpackets = -1;
    PackNos.numberofpackets = numberofpackets;
    int serverLength = sizeof(ServerAddressPort);
    int l = 0;
    while (l == 0)
    {
        if (sendto(sockfdc, (char *)&PackNos, sizeof(PackNos), 0, (struct sockaddr *)&ServerAddressPort, serverLength) == -1)
        {
            printf("Sending Number of Packets Failed\n");
            exit(EXIT_FAILURE);
        }
        if (recvfrom(sockfdc, (char *)&A, sizeof(A), 0, (struct sockaddr *)&ServerAddressPort, &serverLength) == -1)
        {
            printf("Recieving Acknowledgement for numberofpackets failed\n");
            exit(EXIT_FAILURE);
        }
        if (A.numbeofpackets == PackNos.numberofpackets)
        {
            l++;
        }
    }
    Datapackets *Data = (Datapackets *)malloc(sizeof(Datapackets) * numberofpackets);
    int *SentorNot = (int *)malloc(sizeof(int) * numberofpackets);
    for (int i = 0; i < numberofpackets; i++)
    {
        Data[i].index = i;
        strncpy(Data[i].Data, Buffer + (i * 15), 15);
        SentorNot[i] = 0;
    }
    int k = numberofpackets;
    struct timeval time;
    Acknowledgements Ab;
    while (k != 0)
    {
        for (int i = 0; i < numberofpackets; i++)
        {
            if (SentorNot[i] == 0)
            {
                gettimeofday(&time, NULL);
                Data[i].time = time.tv_sec;
                if (sendto(sockfdc, (char *)&Data[i], sizeof(Data[i]), 0, (struct sockaddr *)&ServerAddressPort, serverLength) == -1)
                {
                    printf("Sending %dth packet failed\n", i);
                }
            }
            bzero((char *)&Ab, sizeof(Ab));
            if (recvfrom(sockfdc, (char *)&Ab, sizeof(Ab), MSG_DONTWAIT, (struct sockaddr *)&ServerAddressPort, &serverLength) != -1)
            {
                gettimeofday(&time, NULL);
                time_t hi = time.tv_sec;
                if ((double)(hi - Data[Ab.index].time) <= 0.1)
                {
                    // printf("Recieved Acknowledgement of %dth Datapacket\n", Ab.index);
                    k--;
                    SentorNot[Ab.index] = 1;
                }
            }
        }
    }
    free(Data);
    char buffer[1024]; // Adjust the buffer size as needed
    while (recvfrom(sockfdc, buffer, sizeof(buffer), MSG_DONTWAIT, (struct sockaddr *)&ServerAddressPort, &serverLength) > 0)
    {
        // Discard received data
    }
    Numberofpackets PackNos2;
    Acknum A2;
    A2.numbeofpackets = -1;
    while (A2.numbeofpackets == -1)
    {
        if (recvfrom(sockfdc, (char *)&PackNos2, sizeof(PackNos2), 0, (struct sockaddr *)&ServerAddressPort, &serverLength) == -1)
        {
            printf("Recieving Number of packets Failed\n");
            exit(EXIT_FAILURE);
        }
        A2.numbeofpackets = PackNos2.numberofpackets;
        if (sendto(sockfdc, (char *)&A2, sizeof(A2), 0, (struct sockaddr *)&ServerAddressPort, serverLength) == -1)
        {
            printf("Sending Acknowledgement Failed\n");
            exit(EXIT_FAILURE);
        }
    }
    Datapackets *Data2 = (Datapackets *)malloc(sizeof(Datapackets) * A2.numbeofpackets);
    for (int i = 0; i < A2.numbeofpackets; i++)
    {
        Data2[i].index = -1;
    }
    int k2 = A2.numbeofpackets;
    Datapackets Datay2;
    Acknowledgements Ay2;
    // int nijesh = 0;
    while (k2 != 0)
    {
        bzero((char *)&Datay2, sizeof(Datay2));
        if (recvfrom(sockfdc, (char *)&Datay2, sizeof(Datay2), 0, (struct sockaddr *)&ServerAddressPort, &serverLength) == -1)
        {
            printf("Recieving Number of packets Failed\n");
            exit(EXIT_FAILURE);
        }
        Data2[Datay2.index].index = Datay2.index;
        strcpy(Data2[Datay2.index].Data, Datay2.Data);
        bzero((char *)&Ay2, sizeof(Ay2));
        Ay2.index = Datay2.index;
        // if (Ay2.index % 5 != 0 || nijesh == A.numbeofpackets / 5)
        // {
        if (sendto(sockfdc, (char *)&Ay2, sizeof(Ay2), 0, (struct sockaddr *)&ServerAddressPort, serverLength) == -1)
        {
            printf("Sending Acknowledgement of %dth packet Failed\n", Ay2.index);
            exit(EXIT_FAILURE);
        }
        else
        {
            k2--;
        }
        // }
        // else
        // {
        //     nijesh++;
        // }
    }
    printf("Server: ");
    for (int i = 0; i < A2.numbeofpackets; i++)
    {
        printf("%s", Data2[i].Data);
    }
    free(Data2);
    char bufer[1024]; // Adjust the buffer size as needed
    while (recvfrom(sockfdc, bufer, sizeof(bufer), MSG_DONTWAIT, (struct sockaddr *)&ServerAddressPort, &serverLength) > 0)
    {
        // Discard received data
    }
    // }
    if (close(sockfdc) == -1)
    {
        printf("Closing Socket Failed\n");
        exit(1);
    }
}