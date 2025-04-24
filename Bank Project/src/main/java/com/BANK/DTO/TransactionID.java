package com.BANK.DTO;
import java.util.Random;
public class TransactionID {

    public static long generateTransactionId() {
        Random rd = new Random();
        int num = 0;
        long ans = 0;
        long val =rd.nextLong();
//System.out.println(val);
        if (val < 0)
        {
            val = val *-1;
        }
//System.out.println(val);
        while (num < 15){
            long rem = val % 10;
            ans =(ans*10)+rem;
//System.out.println(rem);
            val = val / 10;
            num+=1;
//System.out.println(ans);
        }
        return ans;
    }
}

